#!/bin/bash
# setup_remote.sh - Execute this ON the Raspberry Pi

echo "=== PiFire Touch: System Setup ==="

# 1. Install System Dependencies for Qt6 EGLFS
echo "--> Installing System Dependencies..."
sudo apt-get update
# "Kitchen sink" dependencies for Qt6/PySide6 on Lite OS
sudo apt-get install -y \
  libgbm1 libgl1-mesa-dri libgl1 libinput10 libxkbcommon-x11-0 \
  libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 \
  libxcb-render-util0 libxcb-render0 libxcb-shape0 libxcb-sync1 libxcb-xfixes0 \
  libxcb-xinerama0 libxcb-xkb1 libxcb1 \
  libx11-xcb1 libdbus-1-3 libfontconfig1 \
  libgles2 libegl1

# 2. Fix Permissions
echo "--> Adding user 'pi' to video/render groups..."
sudo usermod -a -G render pi
sudo usermod -a -G video pi
sudo usermod -a -G tty pi
sudo usermod -a -G input pi

# Grant TTY access for linuxfb fallback
echo "--> Fixing TTY permissions..."
sudo chmod 660 /dev/tty0
sudo chgrp tty /dev/tty0

# 3. Check GPU Driver (KMS)
echo "--> Checking /boot/config.txt for KMS..."
if grep -q "dtoverlay=vc4-kms-v3d" /boot/config.txt; then
    echo " [OK] KMS overlay found."
elif grep -q "dtoverlay=vc4-fkms-v3d" /boot/config.txt; then
    echo " [WARN] Fake KMS (fkms) found. Full KMS (kms) is recommended for Qt6."
else
    echo " [ERR] No KMS overlay found in /boot/config.txt!"
    echo "       Please enable it by adding: dtoverlay=vc4-kms-v3d"
fi

echo "=== Setup Complete ==="
echo "You may need to REBOOT for permissions/drivers to take effect: sudo reboot"
