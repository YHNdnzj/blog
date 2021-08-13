---
title: 最好的軟路由 Powered By Arch Linux（其一：基本網路設定）
date: 2021-08-13 09:10:25
updated: 2021-08-13 09:34:30
tags:
- Linux
- systemd
- Network
- Router
thumbnail: /2021/08/13/arch-is-the-best-router/thumbnail.webp
---

> 自從換了 ROG Zephyrus G14 後，*arch-desktop*（參見 [我的計算機折騰史](/2020/03/08/my-messing-around-with-computers)）便光榮退休了。但我希望能繼續~~壓榨剩餘價值~~讓其發光發熱，便萌生了做軟路由的想法。
>
> <!-- more -->

> 好久沒更新了，其實很久之前就想寫一寫 幻 14 的使用感受的（~~繼續咕咕咕~~

## 作業系統選擇

### Why?

許多軟路由都會選擇 Windows / ESXi 虛擬 OpenWrt 作爲系統，而我作爲~~高貴的~~ Arch 使用者，當然要選擇 Arch 啦。畢竟我使用的是桌面級 CPU，效能較好，用完整的 Linux 也可以跑些其它服務。而且 ArchWiki 甚至有一篇 [Router](https://wiki.archlinux.org/title/Router) 教你如何搭軟路由，不愧是…

### How?

Just follow the [Installation guide](https://wiki.archlinux.org/title/Installation_guide).

如果打算使用軟路由撥號，建議在安裝時先使用 DHCP，待網路基本配置完成，確認內網設備可以聯網後配置 PPP，防止失聯。

## Start Networking!

我選擇使用 `systemd-networkd` 進行介面配置，`resolved` 作爲 DNS Server，`dhcpd` 作爲 DHCPv4 Server。

`# pacman -S dhcpd`

（本想只使用 systemd 組件完成所有工作的，但是 networkd 的 DHCPServer 太難用了…~~不過還是可以少裝幾個包~~）

### 更改網路介面名稱

爲了便於之後的配置，建議使用 udev 規則將網路介面改爲固定、便於記憶的名稱：

```ini
# /etc/udev/rules.d/10-network.rules
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:ff", NAME="extern0"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="ff:ee:dd:cc:bb:aa", NAME="intern0"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="ff:ee:dd:cc:bb:ab", NAME="intern1"
```

此處 `extern*` 爲 WAN 連接埠，`intern*` 爲 LAN。可使用 `ip link` 獲取 (MAC) address。

重新加載 udev 配置：

```console
# udevadm control --reload
# udevadm trigger
```

### WAN (DHCP)

```ini
# /etc/systemd/network/20-wired-external-dhcp.network
[Match]
Name=extern0

[Network]
DHCP=yes
IPv6AcceptRA=yes
IPv6PrivacyExtensions=yes
```

```console
# ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
# systemctl enable --now systemd-networkd systemd-resolved
```

（這一步大概在安裝 Arch 時就已經通過 networkd / dhcpcd 等工具配好了，記得將網路介面名稱改爲上面修改後的，並禁用 networkd 以外的網路管理器）

### LAN

#### systemd-networkd

如果你的 LAN 對應着多個網路介面，需要先[建立 bridge 介面](https://wiki.archlinux.org/title/Systemd-networkd#Bridge_interface)：

```ini
# /etc/systemd/network/br_lan.netdev
[NetDev]
Name=br_lan
Kind=bridge
```

```ini
# /etc/systemd/network/10-bind-br_lan.network
[Match]
Name=intern*

[Network]
Bridge=br_lan
```

然後爲其分配地址：

```ini
# /etc/systemd/network/21-wired-internal.network
[Match]
Name=br_lan

[Link]
Multicast=yes

[Network]
Address=10.0.0.1/24
MulticastDNS=yes
IPMasquerade=both
#IPv6SendRA=yes
#DHCPv6PrefixDelegation=yes

#[IPv6SendRA]
#Managed=yes
#OtherInformation=yes
```

重新加載 networkd 配置：`# networkctl reload`

`Address=` 爲 LAN 所處 IP 網段，可使用 CIDR 計算器計算（參見 [ArchWiki](https://wiki.archlinux.org/title/Router#With_netctl)）。

`Multicast(DNS)=` 爲 [mDNS](https://en.wikipedia.org/wiki/Multicast_DNS) 解析，具體參見 [ArchWiki: systemd-resolved#mDNS](https://wiki.archlinux.org/title/Systemd-resolved#mDNS)。

[DHCPv6 Prefix Delegation](https://wiki.archlinux.org/title/IPv6#Prefix_delegation_(DHCPv6-PD)) 僅在本機撥號時有效，可在配置 PPP 後啓用。

#### systemd-resolved

resolved 自帶 cache 和 DNS Server 功能，可以作爲 DHCP Server 分發的 DNS 使用。

```ini
# /etc/systemd/resolved.conf.d/listen-on-internal.conf
[Resolve]
DNSStubListenerExtra=10.0.0.1
```

`10.0.0.1` 爲上文分配給 LAN 的 IP。

重新加載 resolved 配置：`systemctl restart systemd-resolved`

#### dhcpd

##### 配置

```
# /etc/dhcpd.conf
option domain-name-servers 10.0.0.1, 8.8.8.8;
option subnet-mask 255.255.255.0;
option routers 10.0.0.1;
subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.100 10.0.0.250;
}
```

`8.8.8.8` 爲備用 DNS Server，可留空。

`255.255.255.0`, `10.0.0.1` 與分配給 LAN 的 IP 網段一致。

`range` 爲可下發的 IP 範圍。

更多配置項參考 [ArchWiki: dhcpd#Configuration](https://wiki.archlinux.org/title/Dhcpd#Configuration)。

##### 啓用

dhcpd 預設會運行在所有網路介面上，需要[修改 systemd service](https://wiki.archlinux.org/title/Dhcpd#Service_file)：

`# cp /usr/lib/systemd/system/dhcpd4.service /etc/systemd/system/dhcpd4@.service`

編輯 `/etc/systemd/system/dhcpd4@.service`，將 `ExecStart=` 項改爲：

`ExecStart=/usr/bin/dhcpd -4 -q -cf /etc/dhcpd.conf -pf /run/dhcpd4/dhcpd.pid %I`

啓用修改後的 dhcpd：

```console
# systemctl daemon-reload
# systemctl enable --now dhcpd4@br_lan.service
```

## 未完待續

此時，將電腦接入軟路由的 LAN 口，DHCP 成功獲取 IP，便可以愉快地使用 Arch Router 上網了。

然而，由於 WAN 使用 DHCP，事實上還未擺脫對上級路由的依賴（如果是光貓撥號的話…嘗試改成橋接吧（反正當初電信來安裝的時候我就順便改好了（

所以，下一章會使用 Arch Router 撥號，啓用 IPv6 和 DNS over TLS，優化效能以及搭一些其它服務，讓其成爲 Arch Server（

*To Be Continued*
