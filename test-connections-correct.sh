#!/bin/bash
# test-connections-correct.sh
# Test script with correct ports: LM Studio (8080) and Ollama (11434)

echo "🔍 Testing Local Model Connections for OpenCode"
echo "=================================================="
echo ""

# Test LM Studio on port 8080
echo "📊 Testing LM Studio (port 8080)..."
echo "------------------------------------"
if curl -s --connect-timeout 3 http://localhost:8080/v1/models > /dev/null 2>&1; then
    echo "✅ LM Studio is running on port 8080"
    
    # Get model info
    echo "📋 Available models:"
    curl -s http://localhost:8080/v1/models | jq -r '.data[].id' 2>/dev/null | head -5 || echo "   (Could not parse model list)"
    
    # Test API call
    echo ""
    echo "🧪 Testing API call..."
    response=$(curl -s --connect-timeout 5 -X POST http://localhost:8080/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer lm-studio" \
        -d '{
            "model": "gpt-oss-20b",
            "messages": [{"role": "user", "content": "Say API test successful'"}],
            "max_tokens": 10
        }' 2>/dev/null)
    
    if echo "$response" | grep -q "content"; then
        echo "✅ LM Studio API is working"
        echo "📝 Response: $(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null || echo "   (Could not parse response)")"
    else
        echo "❌ LM Studio API test failed"
        echo "🔍 Error: $response"
    fi
else
    echo "❌ LM Studio is not running on port 8080"
    echo "💡 Fix: Check LM Studio settings for server port (default: 8080)"
fi

echo ""
echo ""

# Test Ollama on port 11434
echo "🦙 Testing Ollama (port 11434)..."
echo "-------------------------------"
if curl -s --connect-timeout 3 http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama is running on port 11434"
    
    # Get model info
    echo "📋 Available models:"
    curl -s http://localhost:11434/api/tags | jq -r '.models[].name' 2>/dev/null | head -5 || echo "   (Could not parse model list)"
    
    # Test API call
    echo ""
    echo "🧪 Testing API call..."
    response=$(curl -s --connect-timeout 5 -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d '{
            "model": "gpt-oss-20b",
            "prompt": "Say API test successful",
            "stream": false
        }' 2>/dev/null)
    
    if echo "$response" | grep -q "response"; then
        echo "✅ Ollama API is working"
        echo "📝 Response: $(echo "$response" | jq -r '.response' 2>/dev/null || echo "   (Could not parse response)")"
    else
        echo "❌ Ollama API test failed"
        echo "🔍 Error: $response"
    fi
else
    echo "❌ Ollama is not running on port 11434"
    echo "💡 Fix: Run 'ollama serve' or start Ollama application"
fi

echo ""
echo ""

# Check OpenCode configuration
echo "⚙️  Testing OpenCode Configuration..."
echo "--------------------------------------"

opencode_dir="$HOME/projects/2026/ai-rules/.opencode"
config_file="$opencode_dir/opencode.json"

if [ -f "$config_file" ]; then
    echo "✅ OpenCode config found at: $config_file"
    
    # Extract model info
    echo "📋 Current configuration:"
    if command -v jq > /dev/null 2>&1; then
        echo "   Provider: $(jq -r '.model.provider // "not set"' "$config_file" 2>/dev/null || echo "   (Could not parse)")"
        echo "   Base URL: $(jq -r '.model.base_url // "not set"' "$config_file" 2>/dev/null || echo "   (Could not parse)")"
        echo "   Model: $(jq -r '.model.model // "not set"' "$config_file" 2>/dev/null || echo "   (Could not parse)")"
        echo "   Port: $(echo $(jq -r '.model.base_url // "not set"' "$config_file" 2>/dev/null) | sed -n 's/.*:\([0-9]*\).*/\1/p' || echo "   (Could not extract port)")"
    else
        echo "   (Install jq to see configuration details)"
    fi
else
    echo "❌ OpenCode config not found at: $config_file"
    echo "💡 Expected location: ~/.opencode/opencode.json or ai-rules/.opencode/opencode.json"
fi

echo ""
echo ""

# Check for common issues
echo "🔍 Common Issues Check..."
echo "-------------------------"

# Check if ports are in use
echo "🔌 Port status:"
if command -v lsof > /dev/null 2>&1; then
    if lsof -i :8080 > /dev/null 2>&1; then
        echo "   Port 8080 (LM Studio): ✅ In use"
    else
        echo "   Port 8080 (LM Studio): ❌ Not in use"
    fi
    
    if lsof -i :11434 > /dev/null 2>&1; then
        echo "   Port 11434 (Ollama): ✅ In use"
    else
        echo "   Port 11434 (Ollama): ❌ Not in use"
    fi
else
    echo "   (Install lsof to check port status)"
fi

# Check for required tools
echo ""
echo "🛠️  Required tools:"
echo "   curl: $(command -v curl > /dev/null 2>&1 && echo "✅ Installed" || echo "❌ Missing")"
echo "   jq: $(command -v jq > /dev/null 2>&1 && echo "✅ Installed" || echo "⚠️  Optional (for better output)")"

echo ""
echo ""
echo "📋 OpenCode Configuration Templates:"
echo "=================================="

echo "For LM Studio (port 8080):"
echo '{
  "model": {
    "provider": "openai",
    "base_url": "http://localhost:8080/v1",
    "model": "gpt-oss-20b",
    "api_key": "lm-studio"
  }
}'

echo ""
echo "For Ollama (port 11434):"
echo '{
  "model": {
    "provider": "ollama",
    "base_url": "http://localhost:11434",
    "model": "gpt-oss-20b",
    "api_key": "ollama"
  }
}'

echo ""
echo "📝 Summary:"
echo "==========="
echo "Test updated with correct LM Studio port (8080)"
echo "Choose your preferred provider and update config accordingly"
echo ""
echo "🚀 Next steps:"
echo "1. Run: cd ~/projects/2026 && ./test-connections-correct.sh"
echo "2. Choose provider (LM Studio or Ollama)"
echo "3. Update .opencode/opencode.json if needed"
echo "4. Start OpenCode and test connection"
echo "5. Proceed with token optimization using BigPickle"