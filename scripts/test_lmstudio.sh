#!/bin/bash

# Test script for LM Studio + OpenCode integration
# This script verifies that LM Studio is running and accessible

set -e

echo "🧪 Testing LM Studio + OpenCode Integration"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check if LM Studio is running
echo "📡 Test 1: Checking LM Studio connectivity..."
if curl -s http://localhost:1234/v1/models > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} LM Studio is running on http://localhost:1234"
else
    echo -e "${RED}✗${NC} LM Studio is not accessible on http://localhost:1234"
    echo ""
    echo "Please ensure:"
    echo "  1. LM Studio application is running"
    echo "  2. Server mode is enabled in LM Studio settings"
    echo "  3. Server is running on port 1234"
    exit 1
fi

# Test 2: Check available models
echo ""
echo "🤖 Test 2: Checking available models..."
MODELS=$(curl -s http://localhost:1234/v1/models | jq -r '.data[].id' 2>/dev/null || echo "")

if [ -z "$MODELS" ]; then
    echo -e "${YELLOW}⚠${NC} Could not retrieve model list (jq may not be installed)"
    echo "Available models response:"
    curl -s http://localhost:1234/v1/models
else
    echo "Available models:"
    echo "$MODELS" | while read -r model; do
        echo "  - $model"
    done
    
    # Check if qwen3-coder is available
    if echo "$MODELS" | grep -q "qwen3-coder"; then
        echo -e "${GREEN}✓${NC} Qwen3-Coder model is available"
    else
        echo -e "${YELLOW}⚠${NC} Qwen3-Coder model not found in available models"
        echo "Please load Qwen3-Coder in LM Studio"
    fi
fi

# Test 3: Verify OpenCode configuration
echo ""
echo "⚙️  Test 3: Verifying OpenCode configuration..."

CONFIG_FILE=".opencode/opencode.json"
if [ -f "$CONFIG_FILE" ]; then
    PROVIDER=$(grep -o '"provider": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
    BASE_URL=$(grep -o '"base_url": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
    MODEL=$(grep -o '"model": "[^"]*"' "$CONFIG_FILE" | head -1 | cut -d'"' -f4)
    
    echo "Configuration:"
    echo "  Provider: $PROVIDER"
    echo "  Base URL: $BASE_URL"
    echo "  Model: $MODEL"
    
    if [ "$PROVIDER" = "lmstudio" ] && [ "$BASE_URL" = "http://localhost:1234" ]; then
        echo -e "${GREEN}✓${NC} OpenCode configuration is correct"
    else
        echo -e "${RED}✗${NC} OpenCode configuration needs updating"
    fi
else
    echo -e "${RED}✗${NC} Configuration file not found: $CONFIG_FILE"
fi

# Test 4: Check all mode configurations
echo ""
echo "📋 Test 4: Checking all mode configurations..."

for mode in plan build review; do
    CONFIG_FILE=".opencode/opencode.${mode}.json"
    if [ -f "$CONFIG_FILE" ]; then
        PROVIDER=$(grep -o '"provider": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
        if [ "$PROVIDER" = "lmstudio" ]; then
            echo -e "${GREEN}✓${NC} $mode mode configured correctly"
        else
            echo -e "${RED}✗${NC} $mode mode needs updating"
        fi
    else
        echo -e "${YELLOW}⚠${NC} $mode mode config not found"
    fi
done

# Test 5: Simple API test
echo ""
echo "🔬 Test 5: Testing simple API call..."
echo "Sending test request to LM Studio..."

RESPONSE=$(curl -s -X POST http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-coder",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 10
  }' 2>/dev/null || echo "")

if [ -n "$RESPONSE" ]; then
    echo -e "${GREEN}✓${NC} API call successful"
    echo "Response preview:"
    echo "$RESPONSE" | head -c 200
    echo "..."
else
    echo -e "${RED}✗${NC} API call failed"
fi

# Summary
echo ""
echo "============================================"
echo "📊 Test Summary"
echo "============================================"
echo ""
echo "All tests completed!"
echo ""
echo "Next steps:"
echo "  1. Ensure LM Studio is running with Qwen3-Coder loaded"
echo "  2. Test OpenCode in each mode:"
echo "     - Plan mode: Read-only architecture design"
echo "     - Build mode: Full implementation capability"
echo "     - Review mode: Code quality analysis"
echo ""
echo "For mode switching, use:"
echo "  cd ~/.config/opencode && ./mode_switch.sh [plan|build|review]"
echo ""