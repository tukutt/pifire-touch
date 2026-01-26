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
  libgles2 libegl1 \
  cage qt6-wayland

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
echo "--> Checking config.txt for KMS..."
CONFIG_FILE="/boot/config.txt"
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
fi
echo "    Using: $CONFIG_FILE"

if grep -q "dtoverlay=vc4-kms-v3d" "$CONFIG_FILE"; then
    echo " [OK] KMS overlay found."
elif grep -q "dtoverlay=vc4-fkms-v3d" "$CONFIG_FILE"; then
    echo " [WARN] Fake KMS (fkms) found. Enabling Full KMS..."
    sudo sed -i 's/dtoverlay=vc4-fkms-v3d/#dtoverlay=vc4-fkms-v3d/g' "$CONFIG_FILE"
    echo "dtoverlay=vc4-kms-v3d" | sudo tee -a "$CONFIG_FILE"
else
    echo " [ERR] No KMS overlay found! Enabling it..."
    echo "dtoverlay=vc4-kms-v3d" | sudo tee -a "$CONFIG_FILE"
fi

# Ensure run_remote works with cage (tty permissions for SSH launch are tricky)
# We add a handy alias or hint for systemd usage later.

echo "=== Setup Complete ==="
echo "You may need to REBOOT for permissions/drivers to take effect: sudo reboot"
