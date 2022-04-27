---
title: 使用 Telegram 收發 WeChat 訊息
date: 2019-05-24 21:09:25
updated: 2020-03-14 20:51:55
tags: 
- EFB
- Linux
- systemd
thumbnail: /2019/05/24/send-and-receive-messages-from-wechat-on-telegram/thumbnail.webp
---

> 本教學使用 [EFB](https://github.com/blueset/ehForwarderBot), [ETM](https://github.com/blueset/efb-telegram-master), [EWS](https://github.com/blueset/efb-wechat-slave) 和 systemd 守護行程，支援 Ubuntu >= 18.04 & Debian >= 10
>
> <!-- more -->
>
> （使用 EWS 有 **WeChat 網頁版被封**的危險，請謹慎使用）
>

## 安裝

建議先使用 `# apt update && apt upgrade -y` 更新所有軟體包

### 二進制依賴

`# apt install -y python3-pip python3-wheel ffmpeg libmagic1 libwebp6`

### 主體

`# pip3 install ehforwarderbot efb-telegram-master efb-wechat-slave`

## 設定

`# mkdir -p /etc/ehforwarderbot/profiles/wechat/blueset.telegram`

### EFB

創建 `/etc/ehforwarderbot/profiles/wechat/config.yaml`，寫入以下內容

```yaml
master_channel: blueset.telegram
slave_channels: 
- blueset.wechat
```

### ETM

#### [創建 Telegram Bot](https://blog.1a23.com/2017/01/09/EFB-How-to-Send-and-Receive-Messages-from-WeChat-on-Telegram-zh-CN/#0x030-创建-Telegram-Bot)

#### 建立設定檔

創建 `/etc/ehforwarderbot/profiles/wechat/blueset.telegram/config.yaml`，寫入以下內容

```yaml
token: "TOKEN"
# 將 TOKEN 替換爲在上一步獲得的 Token
admins: 
- ID
# 將 ID 替換爲在上一步獲得的 Telegram ID
```

### systemd 守護行程

創建 `/etc/systemd/system/efb@.service`，寫入以下內容

```ini
[Unit]
Description=EFB instance for profile %i
Documentation=https://github.com/blueset/ehForwarderBot
Wants=network-online.target
After=network-online.target

[Service]
PrivateTmp=true
ExecStart=/usr/bin/python3 -m ehforwarderbot -p %i
Environment=EFB_DATA_PATH=/etc/ehforwarderbot LANG=zh_CN.UTF-8
TimeoutStopSec=10
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## 運行

`# systemctl start efb@wechat`

使用 `$ journalctl -u efb@wechat -e` 查看輸出，掃碼登入

設定爲開機自啓動：`# systemctl enable efb@wechat`
