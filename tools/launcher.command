#!/bin/bash

# Force the terminal to change directory to where this file lives
DIR="$(pwd)"
cd "$(dirname "$0")"

# Run the unified script (it will handle venv creation & python execution)
./launcher.sh interactive_cropper.py

# Keep terminal open if it crashes so you can read errors
echo ""
read -p "Press [Enter] to close..."
cd "$DIR" || exit 1