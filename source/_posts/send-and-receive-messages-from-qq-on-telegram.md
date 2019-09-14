---
title: 使用 Telegram 收發 QQ 訊息
date: 2019-05-26 03:54:31
updated: 2019-09-14 10:27:10
tags: 
- EFB
thumbnail: /img/thumbnails/efb.jpg
---

> 本教學使用 [EFB](https://github.com/blueset/ehForwarderBot), [ETM](https://github.com/blueset/efb-telegram-master), [EQS](https://github.com/milkice233/efb-qq-slave) 和 systemd 守護行程，支援 Ubuntu >= 18.04 & Debian >= 10
>
> <!-- more -->

## 安裝

建議先使用 `# apt update && apt upgrade -y` 更新所有軟體包

### 二進制依賴

`# apt -y install python3-pip python3-wheel ffmpeg libmagic1 libwebp6`

### 主體

`# pip3 install ehforwarderbot efb-telegram-master efb-qq-slave`

## 設定

`# mkdir -p /etc/ehforwarderbot/profiles/qq/{blueset.telegram,milkice.qq}`

### EFB

創建 `/etc/ehforwarderbot/profiles/qq/config.yaml`，寫入以下內容

```yaml
master_channel: blueset.telegram
slave_channels: 
- milkice.qq
```

### ETM

#### [創建 Telegram Bot](https://blog.1a23.com/2017/01/09/EFB-How-to-Send-and-Receive-Messages-from-WeChat-on-Telegram-zh-CN/#0x030-创建-Telegram-Bot)

#### 建立設定檔

創建 `/etc/ehforwarderbot/profiles/qq/blueset.telegram/config.yaml`，寫入以下內容

```yaml
token: "TOKEN"
# 將 TOKEN 替換爲在上一步獲得的 Token
admins: 
- ID
# 將 ID 替換爲在上一步獲得的 Telegram ID
```

### EQS

#### [CoolQ Client](https://github.com/milkice233/efb-qq-slave/blob/master/doc/CoolQ_zh-CN.rst#方案二手动配置---配置-酷q-端篇)

#### 主體

創建 `/etc/ehforwarderbot/profiles/qq/milkice.qq/config.yaml`，寫入以下內容

```yaml
Client: CoolQ
CoolQ:
  type: HTTP
  access_token: ac0f790e1fb74ebcaf45da77a6f9de47
  api_root: http://127.0.0.1:5700/
  host: 127.0.0.1
  port: 8000
  is_pro: false # 若使用 CoolQ Pro 則爲 true
  air_option:
    upload_to_smms: true
```

### systemd 守護行程

創建 `/etc/systemd/system/efb@.service`，寫入以下內容

```ini
[Unit]
Description=EFB instance for profile %i
Documentation=https://github.com/blueset/ehForwarderBot

[Service]
PrivateTmp=true
ExecStart=/usr/bin/python3 -m ehforwarderbot -p %i
Environment=EFB_DATA_PATH=/etc/ehforwarderbot LANGUAGE=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LC_MESSAGES=zh_CN.UTF-8 LANG=zh_CN.UTF-8
TimeoutStopSec=10
Restart=on-failure
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
```

## 運行

`# systemctl start efb@qq`

設定爲開機自啓動：`# systemctl enable efb@qq`
