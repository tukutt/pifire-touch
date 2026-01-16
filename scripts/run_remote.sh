#!/bin/bash

# Configuration Framebuffer
export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# --- NOUVEAU : Supprimer les curseurs ---

# 1. Supprimer le curseur de la console (le tiret bas qui clignote)
# On écrit le code d'échappement magique dans le terminal actuel
echo -e "\033[?25l"

# 2. Supprimer le curseur de la souris (la flèche), si jamais elle apparaît
export QT_QPA_FB_HIDDEN_CURSOR=1

# ----------------------------------------

cd "$(dirname "$0")/.."

echo "Démarrage..."
# Start Python (without exec, so we can clean up after)
.venv/bin/python src/main.py

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