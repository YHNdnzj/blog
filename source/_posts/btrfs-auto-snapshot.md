---
title: Btrfs 自動創建 Snapshot
date: 2019-09-13 16:28:17
updated: 2020-03-22 06:18:35
tags: 
- Linux
- Btrfs
- systemd
thumbnail: /2019/09/13/btrfs-auto-snapshot/thumbnail.webp
---

> Btrfs 有許多吸引人的特性，其中之一就是 Snapshot。經過搜尋，發現 snapper 等已有的程式有許多我不需要的功能，於是決定使用 Bash Script + systemd Unit 實現
> <!-- more -->

## 安裝

`$ aur_helper -S btrfs-snapshot`

## 運行

### 設定檔示例

```bash
/etc/btrfs-snapshot/root.conf

# vim: set ft=sh:
SUBVOL=/
DEST=/.snapshot/root
NKEEP=10
```

### 啓動 Timer

`# systemctl enable --now btrfs-snapshot.timer`

或

`# systemctl enable --now btrfs-snapshot@root.timer`
