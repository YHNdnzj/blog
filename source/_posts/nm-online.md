---
title: 修復 NetworkManager-wait-online 導致的 network-online.target active 過早
date: 2020-02-17 10:50:36
updated: 2021-08-13 21:16:34
tags:
- Linux
- systemd
- Network
---

> <!-- more -->

systemd 有個 `network-online.target`，許多程式會依賴它以在網路連線成功後纔啓動。但如果使用 NetworkManager 提供的 `NetworkManager-wait-online.service`，會導致某些程式啓動過早，如 shadowsocks-libev 使用域名作爲伺服器地址時報錯 `Temporary failure in name resolution`。

在換用[百合仙子](https://blog.lilydjwg.me/)寫的 [wait-online](https://github.com/lilydjwg/wait-online) 後，問題消失。日誌中可以看到 shadowsocks-libev 確實在 `network-online.target` active 後纔啓動。於是查看 `NetworkManager-wait-online.service`：

```ini
# /usr/lib/systemd/system/NetworkManager-wait-online.service
[Unit]
Description=Network Manager Wait Online
Documentation=man:nm-online(1)
Requires=NetworkManager.service
After=NetworkManager.service
Before=network-online.target

[Service]
# `nm-online -s` waits until the point when NetworkManager logs
# "startup complete". That is when startup actions are settled and
# devices and profiles reached a conclusive activated or deactivated
# state. It depends on which profiles are configured to autoconnect and
# also depends on profile settings like ipv4.may-fail/ipv6.may-fail,
# which affect when a profile is considered fully activated.
# Check NetworkManager logs to find out why wait-online takes a certain
# time.

Type=oneshot
ExecStart=/usr/bin/nm-online -s -q
RemainAfterExit=yes

# Set $NM_ONLINE_TIMEOUT variable for timeout in seconds.
# Edit with `systemctl edit NetworkManager-wait-online`.
#
# Note, this timeout should commonly not be reached. If your boot
# gets delayed too long, then the solution is usually not to decrease
# the timeout, but to fix your setup so that the connected state
# gets reached earlier.
Environment=NM_ONLINE_TIMEOUT=60

[Install]
WantedBy=network-online.target
```

閱讀 `nm-online` 的 [man page](https://man.archlinux.org/man/nm-online.1.en) 後發現，`-s` 是在 NetworkManager 啓動連線時就退出，而非網路連線成功。我選擇使用 drop-in file 來去掉這個選項：

```ini
# /etc/systemd/system/NetworkManager-wait-online.service.d/exit-after-connected.conf
[Service]
ExecStart=
ExecStart=/usr/bin/nm-online -q
```

問題解決。
