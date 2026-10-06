#!/usr/bin/env bash
# Quick launcher for Snake Oil Salesman in Godot 4.x

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="/Users/anirudh/Downloads/Godot_mono.app/Contents/MacOS/Godot"

# Allow environment override or standard location fallback
if [ ! -f "$GODOT_BIN" ]; then
    if command -v godot &>/dev/null; then
        GODOT_BIN="$(command -v godot)"
    elif [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
        GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
    elif [ -f "/Applications/Godot_mono.app/Contents/MacOS/Godot" ]; then
        GODOT_BIN="/Applications/Godot_mono.app/Contents/MacOS/Godot"
    else
        echo "Error: Godot executable not found at $GODOT_BIN or system PATH."
        exit 1
    fi
fi

ensure_assets_imported() {
    local needs_import=0
    if [ ! -d "$PROJECT_DIR/.godot/imported" ]; then
        needs_import=1
    elif [ ! -f "$PROJECT_DIR/.godot/imported/icon49.png-eea6ac26a61af59d7dfc204458b86009.ctex" ]; then
        needs_import=1
    fi

    if [ "$needs_import" -eq 1 ] || [ "$1" == "--reimport" ]; then
        echo "Importing project assets via headless editor..."
        "$GODOT_BIN" --path "$PROJECT_DIR" --headless --editor --quit
        echo "Asset import complete."
    fi
}

if [ "$1" == "--import" ] || [ "$1" == "--reimport" ]; then
    ensure_assets_imported --reimport
elif [ "$1" == "--test" ]; then
    ensure_assets_imported
    echo "Running mechanics test suite..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --headless -s tests/test_gameplay_mechanics.gd --quit
    echo "Running UI presentation test suite..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --headless -s tests/test_ui_presentation.gd --quit
    echo "Running mobile layout test suite..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --headless -s tests/test_mobile_ui.gd --quit
elif [ "$1" == "--editor" ]; then
    echo "Opening project in Godot Editor..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --editor
else
    ensure_assets_imported
    echo "Launching Snake Oil Salesman..."
    "$GODOT_BIN" --path "$PROJECT_DIR"
fi
