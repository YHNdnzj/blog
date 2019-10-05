---
title: Btrfs 自動創建 Snapshot
date: 2019-09-13 16:28:17
updated: 2019-10-05 17:42:12
tags: 
- Linux
- Btrfs
thumbnail: /img/thumbnails/btrfs.webp
---

> Btrfs 有許多吸引人的特性，其中之一就是 Snapshot。經過搜尋，發現 snapper 等已有的程式有許多我不需要的功能，於是決定使用 Bash Script + systemd Unit 實現

## 安裝

`$ aur_helper -S btrfs-snapshot`

## 運行

使用 `$ systemd-escape -p /path/to/mountpoint` 將掛載點轉義爲 C-style "\x2d"

啓動 Timer：`# systemctl enable --now btrfs-snapshot@escaped-path.timer`

目前會自動保留 10 個 Snapshot，如需更改可自行[修改](https://wiki.archlinux.org/index.php/Systemd#Editing_provided_units) systemd service 的 `ExecStart` 項
