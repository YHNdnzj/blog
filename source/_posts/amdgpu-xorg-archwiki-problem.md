---
title: ArchWiki[AMDGPU] 的錯誤配置導致的 NVIDIA PRIME 問題
date: 2021-08-27 19:32:53
updated: 2021-08-29 16:16:41
tags: 
- Linux
- Xorg
- AMDGPU
- NVIDIA
---

[comment]: # (> ArchWiki 是被 Arch 使用者奉爲聖經，且值得所有 Linux 使用者學習、借鑑的百科，但我這次可是着實被坑了一把…（🌚)

> 這是半夜終於發現並解決問題而趁熱寫的吐槽，可能有邏輯不通之處，勿噴（
>
> <!-- more -->

幾天前，無聊~~（實際上作業還沒寫完）~~的我打開 ArchWiki 閒逛，看到 AMDGPU 頁面有個 [Xorg 配置](https://wiki.archlinux.org/title/AMDGPU#Xorg_configuration) 部分，列出了一些看上去還不錯的配置，如 Tear free。我便依照其上進行了配置，重啓後一切正常。我並沒有多加測試~~，反正沒出問題，效果什麼的也沒太大關係吧。~~很快我便忘了此事。

當我幾天後打開 Steam 時，卻發現 systemd-nspawn 報錯，找不到 `/dev/nvidia0`。可 `lsmod` 和 `dmesg` 裏卻只有 nvidia 正常加載的提示。我使用的是 PRIME render offload，並不存在忘記開啓顯卡的問題。重啓無果後，我又嘗試了重新 dkms 編譯 kernel module、關閉 nvidia 的 Early KMS、關閉動態電源管理，均沒有效果。百思不得其解的我發現 `Xorg.0.log` 裏確實有且僅有一行：

`OutputClass "nvidia" ModulePath extended to "/usr/lib/nvidia/xorg,/usr/lib/xorg/modules,/usr/lib/xorg/modules"`

但卻並沒有實際加載 nvidia DDX。可是，無意中打開的 mpv 卻成功使用了 `nvdec-copy` 方式硬解……

更神奇的是，在 mpv 調用硬解後，`/dev` 下竟然出現了久違的 `nvidia0`, `nvidiactl`，但還是缺少 `nvidia-modeset`，而 `prime-run` 也依然無法正常調用 NVIDIA 顯示。經過多次重啓與測試，我發現 `nvidia0` 在使用 `nvidia-smi` 等工具調用後就會出現。問題越發詭異了起來…

走投無路的我不得不開始檢查 nvidia-utils 包的文件。最後，我終於發現了疑似異常之處：`/usr/share/X11/xorg.conf.d` 中的 10-amdgpu.conf 和 10-nvidia-drm-outputclass.conf 中都使用 `Section "OutputClass"` 進行定義，而 ArchWiki 給出的是 `Section "Device"`

於是，我刪除了 `/etc/X11/xorg.conf.d/20-amdgpu.conf`，複製了一份 /usr 中的到 /etc，並在其中添加了 TearFree 和 VRR Option，久違的 `/dev/nvidia*` 終於重現了。

希望以後 ArchWiki 能跟上包裏的改動（（（

話說到最後我也沒能理解爲什麼使用 mpv 和 nvidia-smi 調用 nvidia 後設備文件就會出現，太怪了…
