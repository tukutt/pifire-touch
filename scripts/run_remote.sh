#!/bin/bash

# Configuration Framebuffer (LinuxFB)
export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0
export QT_QPA_FB_HIDDEN_CURSOR=1
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# --- Hide Cursors ---
# 1. Console cursor (requires TTY write access)
echo -e "\033[?25l"
setterm -cursor off 2>/dev/null || true

# 2. Mouse cursor (already set via QT_QPA_FB_HIDDEN_CURSOR)

# ----------------------------------------

cd "$(dirname "$0")/.."

echo "Démarrage (LinuxFB)..."
# Start Python
.venv/bin/python src/main.py

# --- CLEANUP ---
echo "Nettoyage..."

# Restore Console Cursor
echo -e "\033[?25h"
setterm -cursor on 2>/dev/null || true

# --- CLEANUP ---
echo "Nettoyage..."

# Restore Console Cursor
echo -e "\033[?25h"

# Clear Console
clear

# Force clear Framebuffer (Avoid ghosting)
# Attempt to write zeros to fb0. Size calculation varies, just writing "enough" usually works.
# 8MB is plenty for 800x480 or even 1080p.
# "No space left on device" is EXPECTED and means we cleared the whole screen.
if [ -w /dev/fb0 ]; then
   dd if=/dev/zero of=/dev/fb0 bs=1M count=8 status=none 2>/dev/null
fi