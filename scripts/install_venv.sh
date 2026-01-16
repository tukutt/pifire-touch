#!/bin/bash
# Re-install Python Virtual Environment

# Ensure we are in project root
cd "$(dirname "$0")/.."

echo "=== Setting up Python Virtual Environment ==="

if [ -d ".venv" ]; then
    echo "--> Removing existing .venv..."
    rm -rf .venv
fi

echo "--> Creating new .venv..."
python3 -m venv .venv

echo "--> Installing requirements..."
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt

echo "=== Done ==="
