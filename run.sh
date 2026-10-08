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
    elif [ ! -f "$PROJECT_DIR/.godot/imported/icon49.png-eea6ac26a61af59d7dfc204458b86009.ctex" ] || [ ! -f "$PROJECT_DIR/assets/characters/rpg_pack/player_salesman.png.import" ]; then
        needs_import=1
    fi

    if [ "$needs_import" -eq 1 ] || [ "$1" == "--reimport" ]; then
        echo "Importing project assets via headless editor..."
        "$GODOT_BIN" --path "$PROJECT_DIR" --headless --editor --quit
        echo "Asset import complete."
    fi
}

ensure_llm_running() {
    # Check if Ollama or llama-server is listening on port 11434 or 8080
    if curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
        echo "[LLM] Ollama is active on http://127.0.0.1:11434"
        return 0
    elif curl -s http://127.0.0.1:8080/health &>/dev/null; then
        echo "[LLM] llama-server is active on http://127.0.0.1:8080"
        return 0
    fi

    # Try starting Ollama if installed
    local ollama_bin=""
    if command -v ollama &>/dev/null; then
        ollama_bin="$(command -v ollama)"
    elif [ -x "/opt/homebrew/bin/ollama" ]; then
        ollama_bin="/opt/homebrew/bin/ollama"
    elif [ -x "/usr/local/bin/ollama" ]; then
        ollama_bin="/usr/local/bin/ollama"
    fi

    if [ -n "$ollama_bin" ]; then
        echo "[LLM] Starting background Ollama daemon ($ollama_bin serve)..."
        "$ollama_bin" serve &>/dev/null &
        sleep 1.5
        if curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
            echo "[LLM] Ollama daemon successfully started."
        else
            echo "[LLM] Notice: Ollama daemon initializing. Game will connect as soon as ready."
        fi
    else
        echo "[LLM] Notice: No local LLM running. Game will use persona fallback."
        echo "      To enable live AI: install Ollama (https://ollama.ai) and run: ollama pull qwen2.5:0.5b"
    fi
}

if [ "$1" == "--import" ] || [ "$1" == "--reimport" ]; then
    ensure_assets_imported --reimport
elif [ "$1" == "--check-llm" ]; then
    bash "$PROJECT_DIR/check_llm.sh"
elif [ "$1" == "--test" ]; then
    ensure_assets_imported
    echo "Running mechanics test suite..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --headless -s tests/test_gameplay_mechanics.gd --quit
    echo "Running UI presentation test suite..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --headless -s tests/test_ui_presentation.gd --quit
    echo "Running mobile layout test suite..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --headless -s tests/test_mobile_ui.gd --quit
    if curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
        echo "Running LLM live connection test..."
        "$GODOT_BIN" --path "$PROJECT_DIR" --headless -s tests/test_llm_connection.gd
    fi
elif [ "$1" == "--editor" ]; then
    echo "Opening project in Godot Editor..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --editor
else
    ensure_assets_imported
    ensure_llm_running
    echo "Launching Snake Oil Salesman..."
    "$GODOT_BIN" --path "$PROJECT_DIR"
fi
