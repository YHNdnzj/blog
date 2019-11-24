---
title: Btrfs 自動創建 Snapshot
date: 2019-09-13 16:28:17
updated: 2019-10-13 01:48:52
tags: 
- Linux
- Btrfs
thumbnail: /img/thumbnails/btrfs.webp
---

> Btrfs 有許多吸引人的特性，其中之一就是 Snapshot。經過搜尋，發現 snapper 等已有的程式有許多我不需要的功能，於是決定使用 Bash Script + systemd Unit 實現

## 安裝

`$ aur_helper -S btrfs-snapshot`

## 運行

### 設定檔示例

```bash
/etc/btrfs-snapshot/root.conf

# vim:set ft=sh
SUBVOL=/
DEST=/.snapshot/root
NKEEP=10
```

### 啓動 Timer

`# systemctl enable --now btrfs-snapshot.timer`

或

`# systemctl enable --now btrfs-snapshot@root.timer`