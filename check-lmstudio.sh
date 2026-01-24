#!/bin/bash
# Simple LM Studio checker

echo "🔍 Checking LM Studio..."
echo "======================"

# Check common ports
echo "Testing common LM Studio ports..."
for port in 8080 1234 3000 5000; do
    if curl -s --connect-timeout 2 http://localhost:$port/v1/models > /dev/null 2>&1; then
        echo "✅ LM Studio found on port $port"
        echo "Available models:"
        curl -s http://localhost:$port/v1/models | jq -r '.data[].id' 2>/dev/null | head -3
        echo ""
        echo "To use with OpenCode, update config:"
        echo "{"
        echo '  "model": {'
        echo "    \"provider\": \"openai\","
        echo "    \"base_url\": \"http://localhost:$port/v1\","
        echo "    \"model\": \"gpt-oss-20b\","
        echo "    \"api_key\": \"lm-studio\""
        echo "  }"
        echo "}"
        exit 0
    else
        echo "❌ Port $port: Not responding"
    fi
done

echo ""
echo "💡 LM Studio not found on any port!"
echo ""
echo "To start LM Studio server:"
echo "1. Open LM Studio app"
echo "2. Look for one of these:"
echo "   - ⚡ Server button (top right)"
echo "   - Server tab/panel"
echo "   - View → Server"
echo "   - File → Settings → Server"
echo "3. Start server (should show green indicator)"
echo "4. Port should be 8080 (default)"
echo ""
echo "🔍 Checking for LM Studio process..."
ps aux | grep -i lmstudio | grep -v grep || echo "No LM Studio process found"