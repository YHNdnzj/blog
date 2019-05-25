---
title: 使用 Telegram 收發 WeChat 訊息
date: 2019-05-24 21:09:25
tags: 
- EFB
categories: 
- 教學
thumbnail: https://i.loli.net/2019/05/24/5ce806fa3538760979.jpg
---

> 本教程使用 [EFB](https://github.com/blueset/ehForwarderBot), [ETM](https://github.com/blueset/efb-telegram-master), [EWS](https://github.com/blueset/efb-wechat-slave) 和 systemd 守護行程，支援 Ubuntu >= 18.04 & Debian >= 10
>
> <!-- more -->
>
> （使用 EWS 有 **WeChat 網頁版被封**的危險，請謹慎使用）
>

## 安裝

建議先使用 `apt update && apt upgrade -y` 更新所有軟體包

### 二進制依賴

`apt install python3-pip python3-setuptools python3-wheel ffmpeg libmagic1 libwebp6 git -y`

### 主體

`pip3 install ehforwarderbot efb-telegram-master efb-wechat-slave`

## 設定

`mkdir -p ~/.ehforwarderbot/profiles/wechat{,blueset.telegram,blueset.wechat}`

### EFB

創建 `~/.ehforwarderbot/profiles/wechat/config.yaml`，寫入以下內容

```yaml
master_channel: blueset.telegram
slave_channels: 
- blueset.wechat
```

### ETM

#### [創建 Telegram Bot](https://blog.1a23.com/2017/01/09/EFB-How-to-Send-and-Receive-Messages-from-WeChat-on-Telegram-zh-CN/#0x030-创建-Telegram-Bot)

#### 建立設定檔

創建 `~/.ehforwarderbot/profiles/wechat/blueset.telegram/config.yaml`，寫入以下內容

```yaml
token: "$TOKEN"
# 將 $TOKEN 替換爲在上一步獲得的 Token
admins: 
- $ID
# 將 $ID 替換爲在上一步獲得的 Telegram ID
```

### systemd 守護行程

創建 `/etc/systemd/system/`