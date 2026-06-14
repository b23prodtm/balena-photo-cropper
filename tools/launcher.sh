#!/bin/bash
# --- BASH PORTION ---
# This part runs in Bash first to set up OS dependencies, venv, and pip packages.

# Cross-platform way to get the absolute directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/env"

# 1. Detect OS and install system GUI dependencies automatically (Linux only)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "opensuse-tumbleweed" ] || [ "$ID" = "opensuse" ]; then
        if ! rpm -q libglib-2_0-0 Mesa-libGL1 >/dev/null 2>&1; then
            echo "--> [Tumbleweed] Installing missing system libraries..."
            sudo zypper in -y libglib-2_0-0 Mesa-libGL1 libXrender1 libXext6 python3-devel
            sudo zypper in -t pattern devel_basis
        fi
    elif [ "$ID" = "ubuntu" ] || [ "$ID_LIKE" = "debian" ]; then
        if ! dpkg -s libglib2.0-0 libgl1-mesa-glx >/dev/null 2>&1; then
            echo "--> [Ubuntu] Installing missing system libraries..."
            sudo apt-get update && sudo apt-get install -y libglib2.0-0 libgl1-mesa-glx build-essential python3-dev
        fi
    fi
elif [ "$(uname)" = "Darwin" ]; then
    echo "--> [macOS] Detected macOS. Skipping Linux system library checks..."
    # Note: OpenCV wheels on macOS usually bundle their required libraries.
fi

# 2. Bootstrapping the Virtual Environment
if [ ! -d "$VENV_DIR" ]; then
    echo "--> Creating virtual environment at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"    
fi

echo "--> Installing pip dependencies (opencv, numpy)..."
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r "tools/requirements.txt"

# 3. Hand over execution seamlessly to Python inside the venv
exec "$VENV_DIR/bin/python" "$@"
