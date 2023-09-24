---
title: 爲什麼現代 Linux 不再需要 sbin（bin merge 的意義）
date: 2023-09-24 15:33:28
updated: 2023-09-24 22:52:19
tags:
- Linux
thumbnail: /2023/09/24/why-we-dont-need-sbin-anymore/thumbnail.webp
---

> 這篇 blog 源自我最近在 Debian 羣和羣友進行的一次討論。最近，擁有大量歷史包袱的 Debian 也終於完成了 usr merge（雖然 dpkg 那邊還有點問題……）於是，與其相關的 (s)bin merge 也被提及。在討論中，我發現許多人仍認爲現代 Linux 上應該分出 sbin，我在此嘗試打破這個迷思。
>
> <!-- more -->

### 「權限」究竟適用於誰

要回答「sbin 是否還有意義」這個問題，有一個更底層的問題必須先被回答：「權限」事實上/應該作用於誰？思考下面的例子：當我們運行 fdisk 的時候，是我們沒有「運行命令」的權限，還是命令所要訪問的 device node 我們無權訪問？當我們編輯系統配置的時候，是沒有執行編輯器的權限，還是編輯器沒有向某個文件寫入的權限？我想答案很明晰：「命令本身」並沒有/不受所謂的權限限制，本質在於其需要訪問的資源。

瞭解這點後，便可以看出對命令分「權限」並不本質。但是，在早期的 OS 上這樣擬合是有效的，因爲當時的權限控制基本只靠 file permission，而每個命令做的事情也有限（許多命令也就直接提前判斷 UID）。然而，隨着 multi-user/seat, container, (user) namespacing 等概念的出現和普及，權限控制需要更多靈活性。許多全新的機制因此出現在現代 Linux 上。

### 在現代 Linux 上我們是怎麼鑑權的

要做到更靈活的權限管理，首先便是將其細化。大多數的「query」都是無害的，所以變得開放。最典型的例子便是 `ping`——從一開始需要 setuid (root)，到只需要 `cap_net_raw`，再到 `systemd` 預設的 sysctl 配置（`ping_group_range`）就允許任意 user ping。光這一項，就使得 sbin 的語義被大幅弱化——許多命令兼具 query 和 control 的功能，使 sbin 和其它命令間的界限變得模糊。

要更加精細地實現權限控制，就要引入 policy 機制和 daemon，它們使系統能通過環境來實時判斷對資源的訪問是否應該被允許。例如，現代 Linux 上大家都很習慣不需要提權的電源管理（比如直接在 DE 中操作），但這要歸功於 polkit 和 sd-logind。sd-logind 追蹤已登入的 user 及是否爲遠程操作。當整個系統只有一個登入的 user，且並非遠程 session（例如 ssh），那麼即使此 user 沒有任何特殊權限也會被允許執行關機。這很直覺，因爲 user 有對設備的 physical access 且沒有其他人在使用，但依賴某個 daemon 追蹤系統狀態。同理，Wayland 和足夠新的 Xorg 都可以 rootless，因爲 logind 會賦予目前 VT 所對應的 session 訪問 DRM device 的權限。當切換 VT 時，如此獲得的權限能被實時凍結，並傳遞給另一個 session。

另一個非常常見的例子是 userns。對於某些行爲未知的專有應用，regular user 可以使用 `bwrap` 創建不需要特權的 `chroot` 環境，把目標應用關進其中。或者使用功能更多的 container manager，配合完整的 rootfs 進行服務管理。capabilities 也可以 attach to process 而不是 executable，靈活性增加的同時減小了攻擊面。

此時，再回頭看 sbin，是否感覺它也像許多別的歷史包袱一樣，到了該被 drop 的時候呢？

### 即使存在只能以 root 運行的應用

最後，我拋出一個個人觀點：即使真的有某個應用強依賴特權，我們應該對其它 user 隱藏嗎？我自己的答案是否定的，因爲我覺得這會造成更多的 confusion。何況，從 `PATH` 中移除也並不是隱藏，更像是「此地無銀三百兩」。比起 *command not found*，明確的報錯和原因才更加合理，對 sysadmin 也一樣。

綜上所述，在現代 Linux 上，policy-based 的權限機制和 userns 已經使得 access control 這件事變得動態，同時 `PATH` 只包含 `/usr/bin/` 也能降低 user 和 sysadmin 的心智負擔。我覺得既然已經邁出了 usr merge 的一步，bin merge 的普及也是當仁不讓的正確之舉。

### 後補：Fedora 的 proposal

偶然發現 Fedora 也已經有了 bin merge 的 [proposal](https://fedoraproject.org/wiki/Changes/Unify_bin_and_sbin)，而且其理由與本文所述有相同之處（好！

同時在 detail 中還提及了 sbin 的更多歷史，感興趣的也可以去看看。
