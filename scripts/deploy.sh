#!/bin/bash
# Deploy PiFire Touch to Raspberry Pi
cd "$(dirname "$0")/.."

TARGET_IP="${1:-pifire.local}"
TARGET_USER="pi"
TARGET_DIR="/home/pi/pifire-touch"

echo "=== Deploying to $TARGET_USER@$TARGET_IP ==="
# 1. Sync Files
echo "--> Syncing files..."
# Check if rsync is available, else warn user
if ! command -v rsync &> /dev/null; then
    echo "Error: rsync not found. Please install rsync (e.g. sudo apt install rsync) or copy files manually."
    exit 1
fi
rsync -avz -e "ssh -o StrictHostKeyChecking=no" --exclude '__pycache__' --exclude '*.pyc' --exclude '.git' --exclude '.venv' ./ $TARGET_USER@$TARGET_IP:$TARGET_DIR

# 2. Install Dependencies (in .venv)
echo "--> Setting up virtual environment on remote..."
# Force remove existing .venv (in case it was copied corrupted) and recreate
#ssh $TARGET_USER@$TARGET_IP "cd $TARGET_DIR && rm -rf .venv && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"


echo "=== Deployment Complete ==="
echo "IMPORTANT: First Time Setup (Run this once on Pi):"
echo "  ssh $TARGET_USER@$TARGET_IP '$TARGET_DIR/scripts/setup_remote.sh'"
echo ""
echo "To run on the Pi (Recommended - DSI 5\" - GPU):"
echo "  ssh $TARGET_USER@$TARGET_IP '$TARGET_DIR/scripts/run_remote.sh'"
echo ""
echo "Debug Mode:"
echo "  ssh $TARGET_USER@$TARGET_IP 'cd $TARGET_DIR && .venv/bin/python3 src/main.py -platform linuxfb'"
