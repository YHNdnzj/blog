---
title: 修復 NetworkManager-wait-online 導致的 network-online.target active 過早
date: 2020-02-17 02:50:36
updated: 2020-03-19 02:39:00
tags:
- Linux
- systemd
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
Type=oneshot
ExecStart=/usr/bin/nm-online -s -q --timeout=30
RemainAfterExit=yes

[Install]
WantedBy=network-online.target
```

閱讀 `nm-online` 的 [man page](https://jlk.fjfi.cvut.cz/arch/manpages/man/extra/networkmanager/nm-online.1.en) 後發現，`-s` 是在 NetworkManager 啓動連線時就退出，而非網路連線成功。我選擇使用 drop-in file 來去掉這個選項：

```ini
# /etc/systemd/system/NetworkManager-wait-online.service.d/exit-after-connected.conf
[Service]
ExecStart=
ExecStart=/usr/bin/nm-online -q --timeout=30
```

問題解決。
