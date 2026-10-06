#!/usr/bin/env bash
# Quick launcher for Snake Oil Salesman in Godot 4.x

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="/Users/anirudh/Downloads/Godot_mono.app/Contents/MacOS/Godot"

if [ ! -f "$GODOT_BIN" ]; then
    echo "Error: Godot executable not found at $GODOT_BIN"
    exit 1
fi

if [ "$1" == "--test" ]; then
    echo "Running headless test suite..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --headless -s tests/test_gameplay_mechanics.gd --quit
elif [ "$1" == "--editor" ]; then
    echo "Opening project in Godot Editor..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --editor
else
    echo "Launching Snake Oil Salesman..."
    "$GODOT_BIN" --path "$PROJECT_DIR"
fi
