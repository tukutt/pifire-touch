#!/bin/bash
# install_service.sh - Install PiFire Touch as a Systemd Service

cd "$(dirname "$0")/.."

echo "=== Installing Systemd Service ==="

SERVICE_FILE="pifire-touch.service"
TARGET_PATH="/etc/systemd/system/$SERVICE_FILE"

if [ ! -f "$SERVICE_FILE" ]; then
    echo "Error: Service file not found within repository."
    exit 1
fi

echo "--> Copying service file to $TARGET_PATH..."
sudo cp "$SERVICE_FILE" "$TARGET_PATH"
sudo chmod 644 "$TARGET_PATH"

echo "--> Reloading daemon..."
sudo systemctl daemon-reload

echo "--> Enabling service..."
sudo systemctl enable pifire-touch.service

echo "=== Installation Complete ==="
echo "To start now: sudo systemctl start pifire-touch"
echo "To stop:      sudo systemctl stop pifire-touch"
echo "To reboot:    sudo reboot"
