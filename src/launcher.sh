#!/bin/bash
# pifire-touch launcher (LinuxFB mode)

# 1. Hide Console Cursor
echo -e "\033[?25l" > /dev/tty1
setterm -cursor off > /dev/tty1

# 2. Environment Variables
export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0
export QT_QPA_FB_HIDDEN_CURSOR=1
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export PYTHONUNBUFFERED=1

# 3. Launch App
echo "Starting PiFire Touch..."
/home/pi/pifire-touch/.venv/bin/python3 /home/pi/pifire-touch/src/main.py

# 4. Cleanup (Restore cursor on exit)
echo -e "\033[?25h" > /dev/tty1
setterm -cursor on > /dev/tty1
