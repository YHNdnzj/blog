---
title: 在 Xwayland on Sway 上用上真正 High 的 DPI
date: 2022-10-17 02:18:10
updated: 2022-10-22 18:18:38
tags:
- Linux
- Wayland
- Xwayland
- HiDPI
- Sway
thumbnail: /2022/10/17/sway-xwayland-real-hidpi/thumbnail.webp
---

> 自從換上 Sway，我就開始強烈避免使用 X11 應用，最大的原因便是糊成一團的 *LowDPI*；而這對於 Wine/Proton 遊戲更是噩夢，體驗直接回到 PS3 時代……再看另兩家主流 DE，GNOME 不開分數倍縮放倒是不糊，而 KDE 在 5.26 剛剛引入讓 Xwayland 不糊的選項，體驗也只能算是 degraded。最近，我終於讓 Sway 上的 Xwayland 應用清晰起來，遂在此留下記錄。
>
> <!-- more -->

## Xwayland HiDPI 的糟糕現狀

那麼，Xwayland 爲什麼縮放下會糊呢？因爲 Wayland 的縮放是 compositor 告訴應用需要縮放多少倍，然後支援的應用會告訴 compositor 自己究竟縮放了幾倍（由於 Wayland 的原生分數倍縮放支援還在 [協議起草階段](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/merge_requests/143)，目前的混成器都是通過先讓應用 scale 到某個整數倍再 downscale 實現的，例如 1.5 倍時應用自身實際縮放到了兩倍）。但是對於目前還不支援縮放（主要是 X11 也沒有特別統一的縮放機制，很多時候要靠改 font DPI / toolkit 自己的設定）的 Xwayland 窗口，混成器會直接自己 upscale 到對應的大小，自然就成了 *LowDPI*。KDE 的新選項便是讓 KWin 不要自己 upscale，而是讓 Xwayland 以 scale=1 的模式輸出，縮放交給用戶自己以 X11 的方式告訴應用縮放。

## Sway 上的解決方案

看到 KDE 的方案，在看本文的你應該已經有了一些想法：只要讓 Sway 也不要 upscale Xwayland 窗口就好了——爲此我們實際上需要 patch 其使用的庫 [wlroots](https://gitlab.freedesktop.org/lilydjwg/wlroots/-/tree/lilydjwg) 和 [Xwayland](https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/733)，隨後 rebuild sway 以讓其使用新的 wlroots。對於 Arch 使用者，[我的源](https://repo.yhndnzj.com) 和 AUR 有打好的包可供使用：

`$ paru -S xorg-xwayland-hidpi-xprop wlroots-hidpi-xprop-git sway-im-git`

> `sway-im-git` 是帶有 IME popup（所謂「輸入法候選框」）支援的 `sway-git`，既然都自己編譯了不如順便用上？🌝

### 配置 Xwayland

> 此步驟依賴 `xorg-xprop`, `xorg-xrdb` 和 `xsettingsd`

重啓 sway 之後，我們需要讓 Xwayland 告訴 sway 自己的縮放倍數，這樣 sway 便不會嘗試 upscale 了。大多數情況下爲 2 倍：

`$ xprop -root -format _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2`

注意不要在這裏填寫小數，因爲此解決方案對於分數倍縮放依然使用應用 scale 到整數倍 + sway downscale 的方案，只是這裏的應用爲所有 Xwayland 窗口。

此時，打開一些 Xwayland 應用，出現的會是清晰但極小的 UI。這便是因爲雖然 Xwayland 聲稱應用縮放到了兩倍，但事實上應用並不知道需要縮放的倍數。接下來，就需要使用 X11 的方式來告訴應用這些了。

#### X11 上的縮放

大多數應用（包括 Qt）會使用 X server (Xwayland) 的 `Xft.dpi` 中設定的 DPI（其數值爲 `[Xwayland_scale] * 96`，前者即上文中使用 `xprop` 傳遞給 Xwayland 的縮放倍數）。2 倍對應的爲 `192`：

`$ xrdb -merge <<< 'Xft.dpi: 192'`

此時，許多 Xwayland 應用應該已經能清晰且縮放正確地運行，除了那些~~糟糕的~~需要 `xsettingsd` 的 GDK 應用。它們不使用 X server 提供的值，而是從 `xsettingsd` 處獲取原始 DPI 和縮放倍數。爲此需要配置 `xsettingsd`：

```
# ~/.config/xsettingsd/xsettingsd.conf
Gdk/UnscaledDPI 98304
Gdk/WindowScalingFactor 2
```

隨後啓動之：

`$ xsettingsd`

此時，絕大多數 GDK 應用也已工作。對於運行在 `flatpak` 等無法訪問 `xsettingsd` 的環境的應用，請使用 `GDK_SCALE=2` 單獨爲應用指定縮放倍數。如果依舊存在不遵循縮放的應用，可以試着在 [ArchWiki: HiDPI](https://wiki.archlinux.org/title/HiDPI) 尋求解決方案。

### 持久化

測試可用後，可以將其寫入 sway 的配置進行持久化：

```
exec_always {
    xprop -root -format _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2
    xrdb -merge <<< 'Xft.dpi: 192'
    xsettingsd
}
```

重啓 sway 後隨意打開 Xwayland 應用，即可享受真正的 HiDPI（

## Known issues

- 鼠標指針大小不正確（Xwayland 應用需要 `XCURSOR_SIZE` 設爲 `original_size * [Xwayland_scale]`，然而由於 Wayland 應用也使用此環境變量中指定的大小而無法兼得……可通過單獨修改 Xwayland 應用的 desktop file 緩解）
- Xwayland 應用將會獲取到錯誤的解析度（主要針對遊戲，可使用 [gamescope](https://github.com/Plagman/gamescope) 解決）

## Acknowledgement

- 依雲：wlroots patch 作者（她針對 Wayfire 的 [博文](https://blog.lilydjwg.me/2021/11/20/wayfire-migration-2.215977.html)）
- q234rty：`xorg-xwayland-hidpi-xprop`, `wlroots-hidpi-xprop-git`, `sway-im-git` 的打包者、本文大多數內容的貢獻者

## 最後的一點吐槽

Xwayland 現在已經有數個縮放相關的 patch 了，而且使用不同方式完成，甚至有 issue [彙總](https://gitlab.freedesktop.org/xorg/xserver/-/issues/1318)（……希望能更快地確定一個方案，讓 wlroots 上游用上。

以及 sway 的開發週期也太長了，而且基本不 backport 東西…所以順便用上 `-git` 也不錯（🌚（只是什麼時候有 DBus menu support 啊草
