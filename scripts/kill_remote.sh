#!/bin/bash
# Kill running PiFire Touch instances

echo "Stopping PiFire Touch..."
pkill -f "main.py"
echo "Done."
