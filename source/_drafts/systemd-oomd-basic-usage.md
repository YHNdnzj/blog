---
title: systemd-oomd 基本使用
date:
tags: 
- Linux
- systemd
---

> systemd 247 引入了自己的 OOM killer systemd-oomd（~~「systemd，你個 init 又吞併功能了」~~，瞭解後發現其可以更好地針對 cgroup 進行 OOM 監控/管理。但其文檔並不豐富、缺少示例配置，於是打算介紹一下其基本使用。
>
> <!-- more -->

> 2021 年末本想試着寫年終總結，結果和之前提過的 幻 14 的使用感受、軟路由之後幾篇一起拖到了 2022
>
> 而且看來還要拖很久的樣子（~~其它可以拖，但年終總結是有時間限制的啊~~

> 上段引言是 2022 年 2 月寫的，當時預計可以寫完這篇，結果一路拖到 4 月上網課纔有時間…
>
> （~~這傢伙真能拖~~年終總結什麼的還是別想了（🌚

## 前言：swap 和 cgroup

雖然現代無論是桌機還是筆電的 RAM 都基本 >= 16 GiB，一般不會 OOM，但 swap 空間依然是必要的。[systemd-oomd 的 man page](https://man.archlinux.org/man/systemd-oomd.8#SETUP_INFORMATION) 引用了一篇名爲 *In defence of swap: common misconceptions* 的文章，farseerfc 老師的 blog 有其翻譯：[替 swap 辯護：常見的誤解](https://farseerfc.me/in-defence-of-swap.html)。這在記憶體空間不足時給 systemd-oomd 足夠的時間響應，更對系統穩定性有幫助。如果沒有預留 swap partition，可以根據 ArchWiki 設定 swapfile。

systemd-oomd 依靠 cgroups v2 工作，且觸發 OOM 時殺死整個 cgroup 下的進程，所以建議使每個 desktop app 跑在獨立的 cgroup scope 裏。在 GNOME、KDE 等現代 DE 中，這是預設行爲；Sway 使用者可參考 [ArchWiki: Sway#Manage_Sway-specific_daemons_with_systemd](https://wiki.archlinux.org/title/Sway#Manage_Sway-specific_daemons_with_systemd)。

<details>
    <summary>兩年前第一次嘗試 sway + userspace OOM killer (oomd) 時的悲劇</summary>

    ![log](systemd-oomd-basic-usage/log.jpg)
    
    ![chat](systemd-oomd-basic-usage/chat.jpg)

</details>

## 開始設定

既然是 systemd 組件，在 Arch 上自然包含在 systemd 包中，配置位於 `/etc/systemd/oomd.conf`。預設配置在我這裏夠用了，沒有進行調整，具體可參考 `man oomd.conf`

設定完成後直接啓用之：

`# systemctl enable --now systemd-oomd`

接下來到了關鍵部分：systemd-oomd 並不像 oomd 一樣預設對所有 cgroup 啓用。相反地，其需要手動在各 cgroup 上設定策略。根據 [man 5 systemd.resource-control](https://man.archlinux.org/man/systemd.resource-control.5.en)，有以下選項可供使用：

`ManagedOOMMemoryPressure=`：根據記憶體用量進行 OOM kill，閾值在 `ManagedOOMMemoryPressureLimit=` 中指定

`ManagedOOMSwap=`：根據 Swap 用量進行 OOM kill



對於可以在 `-.slice` 上設定全局策略：

```ini
# /etc/systemd/system/-.slice.d/systemd-oomd.conf
[Slice]
ManagedOOMSwap=kill
```

對於用戶級應用：

```ini
# /etc/systemd/system/user@.service.d/systemd-oomd.conf
[Slice]

```

