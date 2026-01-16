#!/bin/bash
# Helper to run PiFire Touch on Desktop (Linux)

echo "Setting up environment..."
export QT_QUICK_CONTROLS_STYLE=Material
export QT_QUICK_CONTROLS_MATERIAL_THEME=Dark
export QT_QUICK_CONTROLS_MATERIAL_ACCENT=DeepOrange

echo "Starting PiFire Touch..."
cd "$(dirname "$0")/.."
if [ -f "./.venv/bin/python3" ]; then
    ./.venv/bin/python3 src/main.py
else
    python3 src/main.py
fi
