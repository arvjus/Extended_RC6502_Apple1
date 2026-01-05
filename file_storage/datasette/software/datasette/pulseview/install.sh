#!/bin/bash
# Installation script for Datasette PulseView decoder

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.local/share/libsigrokdecode/decoders/datasette"

echo "Installing Datasette decoder to: $TARGET_DIR"

mkdir -p "$TARGET_DIR"
cp "$SCRIPT_DIR/__init__.py" "$TARGET_DIR/"
cp "$SCRIPT_DIR/pd.py" "$TARGET_DIR/"

echo "Done. Restart PulseView to use the decoder."
