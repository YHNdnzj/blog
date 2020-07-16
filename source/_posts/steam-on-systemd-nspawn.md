---
title: 在 systemd-nspawn 上運行 Steam
date: 2020-03-16 09:58:23
updated: 2020-03-25 15:46:11
tags:
- Linux
- systemd
thumbnail: https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Steam_icon_logo.svg/1920px-Steam_icon_logo.svg.png
---

> Steam 依賴許多 32-bit lib，鑑於此我沒有在 host 使用 pacman 安裝它。flatpak 等第三方包管理器由於潔癖，同樣沒有考慮。此時，systemd-nspawn 便成爲了很好的選擇。

## 創建 Container

```console
# pacman -Syu arch-install-scripts
# cd /var/lib/machines
# mkdir arch-nspawn
# pacstrap -c arch-nspawn base
```

## 配置 Container

### 允許訪問 getty

編輯 `/var/lib/machines/arch-nspawn/etc/securetty`，加入 `pts/0` 至 `pts/9`.

### 掛載需要的 Device file 和 Socket

```ini
# cat /etc/systemd/nspawn/arch-nspawn.nspawn
[Exec]
Boot=true
PrivateUsers=no

[Files]
# Xorg
BindReadOnly=/tmp/.X11-unix

# GPU
Bind=/dev/dri

# NVIDIA
Bind=/dev/nvidia0
Bind=/dev/nvidiactl
Bind=/dev/nvidia-modeset
Bind=/dev/shm

# Controller
Bind=/dev/input

# PulseAudio
BindReadOnly=/run/user/$UID/pulse

# AppIndicator
BindReadOnly=/run/user/$UID/bus

[Network]
VirtualEthernet=no
```

`# systemctl edit systemd-nspawn@arch-nspawn.service`

```ini
[Service]
# GPU
DeviceAllow=/dev/dri rw

# NVIDIA
DeviceAllow=/dev/nvidia0 rw
DeviceAllow=/dev/nvidiactl rw
DeviceAllow=/dev/nvidia-modeset rw
DeviceAllow=/dev/shm rw

# Controller
DeviceAllow=char-usb_device rwm
DeviceAllow=char-input rwm
```

### 允許連接 X Server

`$ xhost +local:`

## 配置 Steam

```console
# machinectl start arch-nspawn
# machinectl login arch-nspawn
```

以 root 登入，安裝 [Steam](https://wiki.archlinux.org/index.php/Steam#Installation) 和 [OpenGL 驅動](https://wiki.archlinux.org/index.php/Xorg#Driver_installation)。

由於某些程式直接使用 ALSA，需要安裝 `pulseaudio-alsa`. 但其依賴 `pulseaudio`，於是使用 pacman 的 `--assume-installed` 選項跳過。

`# pacman -S --assume-installed pulseaudio pulseaudio-alsa`

建立一個新的使用者，注意要與 Host 運行 D-Bus, PulseAudio 的 UID 相同。

此時應該可以啓動 Steam 了：

`DISPLAY=:0 PULSE_SERVER=unix:/run/user/$UID/pulse/native steam`
