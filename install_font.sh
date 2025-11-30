#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Installing Cascadia Code on macOS..."
    brew install --cask font-cascadia-mono-nf
else
    echo "Installing Cascadia Code on Linux..."
    FONT_URL="https://github.com/microsoft/cascadia-code/releases/download/v2407.24/CascadiaCode-2407.24.zip"
    FONT_DIR="$HOME/.local/share/fonts"
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    mkdir -p "$FONT_DIR"
    curl -L "$FONT_URL" -o "$TEMP_DIR/CascadiaCode.zip"
    unzip -o "$TEMP_DIR/CascadiaCode.zip" -d "$TEMP_DIR/CascadiaCode"
    find "$TEMP_DIR/CascadiaCode" -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
    fc-cache -fv
fi

echo "Cascadia Code installed successfully!"
