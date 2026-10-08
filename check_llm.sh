#!/usr/bin/env bash
# LLM Health & Connection Diagnostics for Snake Oil Salesman

echo "======================================================="
echo "🧠 SNAKE OIL SALESMAN - LLM CONNECTION CHECKER"
echo "======================================================="

OLLAMA_PORT=11434
LLAMA_PORT=8080
LMSTUDIO_PORT=1234

check_endpoint() {
    local url="$1"
    local timeout=2
    curl -s --connect-timeout "$timeout" "$url"
}

# 1. Check Ollama
echo ""
echo "▶ Checking Ollama (http://127.0.0.1:$OLLAMA_PORT)..."
OLLAMA_TAGS=$(check_endpoint "http://127.0.0.1:$OLLAMA_PORT/api/tags")

if [ -n "$OLLAMA_TAGS" ]; then
    echo "  🟢 Ollama server is RUNNING!"
    MODELS=$(echo "$OLLAMA_TAGS" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$MODELS" ]; then
        echo "  📦 Available models:"
        for m in $MODELS; do
            echo "     • $m"
        done
        
        # Test generation with first model
        FIRST_MODEL=$(echo "$MODELS" | head -n1)
        echo ""
        echo "  🧪 Testing inference with model '$FIRST_MODEL'..."
        START_TIME=$(date +%s)
        TEST_RESP=$(curl -s --connect-timeout 10 "http://127.0.0.1:$OLLAMA_PORT/api/generate" -d "{
            \"model\": \"$FIRST_MODEL\",
            \"prompt\": \"You are Barnaby, a medieval merchant. Greet the player in 1 short sentence.\",
            \"stream\": false
        }")
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        REPLY_TEXT=$(echo "$TEST_RESP" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$REPLY_TEXT" ]; then
            echo "  ✅ Inference SUCCESS (${DURATION}s): \"$REPLY_TEXT\""
        else
            echo "  ⚠️ Response received but could not extract text: $TEST_RESP"
        fi
    else
        echo "  ⚠️ Ollama is running but NO models are downloaded."
        echo "     Run: ollama pull qwen2.5:0.5b"
    fi
else
    echo "  🔴 Ollama server is NOT running on port $OLLAMA_PORT."
    if command -v ollama &>/dev/null; then
        echo "     (Ollama is installed. You can start it with: ollama serve &)"
    else
        echo "     (Ollama is not installed on system PATH.)"
    fi
fi

# 2. Check llama-server
echo ""
echo "▶ Checking llama-server / llama.cpp (http://127.0.0.1:$LLAMA_PORT)..."
LLAMA_CHECK=$(check_endpoint "http://127.0.0.1:$LLAMA_PORT/health")
if [ -n "$LLAMA_CHECK" ]; then
    echo "  🟢 llama-server is RUNNING on port $LLAMA_PORT!"
else
    echo "  ⚪ No server detected on port $LLAMA_PORT (offline)."
fi

# 3. Check LM Studio / OpenAI-compatible
echo ""
echo "▶ Checking OpenAI-compatible local server (http://127.0.0.1:$LMSTUDIO_PORT)..."
LM_CHECK=$(check_endpoint "http://127.0.0.1:$LMSTUDIO_PORT/v1/models")
if [ -n "$LM_CHECK" ]; then
    echo "  🟢 Local OpenAI-compatible server is RUNNING on port $LMSTUDIO_PORT!"
else
    echo "  ⚪ No server detected on port $LMSTUDIO_PORT (offline)."
fi

echo ""
echo "-------------------------------------------------------"
echo "🏁 DIAGNOSTIC COMPLETE"
echo "-------------------------------------------------------"
