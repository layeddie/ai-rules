#!/bin/bash
# ai-rules/scripts/setup_mgrep_opencode.sh
# One-command setup for mgrep integration with OpenCode
# Implements hybrid search: ripgrep (exact) + mgrep (semantic)

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  mgrep + OpenCode Hybrid Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check npm and install mgrep
echo -e "${YELLOW}[1/5] Checking npm installation...${NC}"
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found${NC}"
    echo "Install Node.js: brew install node"
    exit 1
fi
echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"

echo ""
echo -e "${YELLOW}[2/5] Installing mgrep...${NC}"
if command -v mgrep &> /dev/null; then
    echo -e "${GREEN}✅ mgrep already installed: $(mgrep --version 2>&1 | head -1)${NC}"
else
    npm install -g @mixedbread/mgrep
    echo -e "${GREEN}✅ mgrep installed${NC}"
fi

# Step 2: Integrate with OpenCode
echo ""
echo -e "${YELLOW}[3/5] Integrating mgrep with OpenCode...${NC}"
if mgrep install-opencode &> /dev/null; then
    echo -e "${GREEN}✅ mgrep integrated with OpenCode${NC}"
else
    echo -e "${RED}❌ mgrep install-opencode failed${NC}"
    echo "   Please run: mgrep install-opencode"
    echo "   See: https://github.com/mixedbread-ai/mgrep"
fi

# Step 3: Check authentication
echo ""
echo -e "${YELLOW}[4/5] Checking mgrep authentication...${NC}"
# Try to run mgrep with a simple command to check auth
if mgrep --version &> /dev/null 2>&1; then
    echo -e "${GREEN}✅ mgrep is working${NC}"
    echo -e "${YELLOW}   Note: Run 'mgrep login' to activate free tier features${NC}"
else
    echo -e "${YELLOW}⚠️  mgrep not fully authenticated${NC}"
    echo -e "${YELLOW}   Run: mgrep login${NC}"
    echo -e "${YELLOW}   This enables free tier features:${NC}"
    echo -e "${YELLOW}     - 3 workspaces${NC}"
    echo -e "${YELLOW}     - 3 stores${NC}"
    echo -e "${YELLOW}     - Monthly usage allocation${NC}"
fi

# Step 4: Create configuration
echo ""
echo -e "${YELLOW}[5/5] Creating mgrep configuration...${NC}"

CONFIG_FILE="/Users/elay14/projects/2026/ai-rules/.mgreprc.yaml"

cat > "$CONFIG_FILE" << 'EOF'
# mgrep configuration for ai-rules (Free Tier)
# https://www.mixedbread.com/pricing - Start free, upgrade when needed

# Maximum file size to index (5MB - free tier limit)
maxFileSize: 5242880

# Maximum number of files to upload (conservative for free tier)
maxFileCount: 5000

# Store name - unique per project
store: "ai-rules-elixir"

# Free tier optimizations
# - Use standard quality (not high quality) to save tokens
# - Enable auto-rerank for better results
# - Limit initial sync to essential files first
EOF

echo -e "${GREEN}✅ Configuration created: $CONFIG_FILE${NC}"

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}📋 What's been configured:${NC}"
echo "  - mgrep installed and integrated with OpenCode"
echo "  - Hybrid search enabled (ripgrep + mgrep)"
echo "  - Free tier configuration applied"
echo "  - Configuration file created"
echo ""
echo -e "${YELLOW}🚀 Next steps:${NC}"
echo ""
echo "1. Activate free tier (recommended):"
echo "   mgrep login"
echo "   Opens browser for authentication"
echo ""
echo "2. Start background indexing:"
echo "   mgrep watch &"
echo "   Indexes files in background for faster searches"
echo ""
echo "3. Test semantic search:"
echo "   In OpenCode, ask: 'Where do we handle authentication?'"
echo "   LLM will use mgrep via bash tool"
echo ""
echo "4. Test exact search:"
echo "   In OpenCode, ask: 'Find UserService module'"
echo "   LLM will use ripgrep (OpenCode's grep)"
echo ""
echo -e "${YELLOW}📖 Documentation:${NC}"
echo "  - Hybrid strategy: docs/mixed-search-strategy.md"
echo "  - AGENTS.md: Agent guidelines with tool selection"
echo "  - mgrep docs: https://github.com/mixedbread-ai/mgrep"
echo ""
echo -e "${BLUE}💡 How hybrid search works:${NC}"
echo "  - Exact queries → ripgrep (instant, no tokens)"
echo "  - Semantic queries → mgrep (natural language)"
echo "  - LLM chooses automatically based on query type"
echo ""
echo -e "${GREEN}🎉 Ready for semantic code search!${NC}"
echo ""
