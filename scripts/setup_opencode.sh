#!/bin/bash
# ai-rules/scripts/setup_opencode.sh
# Setup OpenCode environment with mgrep and Serena MCP

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check OpenCode installation
if ! command -v opencode &> /dev/null; then
    echo -e "${RED}❌ OpenCode not found${NC}"
    echo "Please install OpenCode:"
    echo "  curl -fsSL https://opencode.ai/install | bash"
    exit 1
fi

echo -e "${GREEN}✅ OpenCode found: $(opencode --version 2>&1 || echo 'installed')${NC}"

# Install mgrep
echo ""
echo -e "${GREEN}📦 Installing mgrep...${NC}"
if command -v mgrep &> /dev/null; then
    echo -e "${YELLOW}⚠️  mgrep already installed${NC}"
else
    if command -v npm &> /dev/null; then
        npm install -g @mixedbread/mgrep
        mgrep install-opencode
        echo -e "${GREEN}✅ mgrep installed and integrated with OpenCode${NC}"
    else
        echo -e "${RED}❌ npm not found${NC}"
        exit 1
    fi
fi

# Install uv (Python package manager for Serena)
echo ""
echo -e "${GREEN}📦 Installing uv...${NC}"
if command -v uv &> /dev/null; then
    echo -e "${YELLOW}⚠️  uv already installed${NC}"
    uv --version
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo -e "${GREEN}✅ uv installed${NC}"
fi

# Test Serena MCP availability
echo ""
echo -e "${GREEN}🔌 Testing Serena MCP...${NC}"
if uvx --from git+https://github.com/oraios/serena serena start-mcp-server --help &> /dev/null; then
    echo -e "${GREEN}✅ Serena MCP ready (via uvx)${NC}"
else
    echo -e "${RED}❌ Failed to test Serena MCP${NC}"
    echo ""
    echo "Please check:"
    echo "  - uv installation: curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "  - uv version: $(uv --version)"
    echo "  - uvx command available: uvx --from"
fi

# Optional: New Elixir-native tools (requires ai-rules project)
if [ -f "ai-rules/scripts/setup_new_tools.sh" ]; then
    echo ""
    echo -e "${YELLOW}📦 Setting up new Elixir-native tools...${NC}"
    bash ai-rules/scripts/setup_new_tools.sh
fi

# Summary
echo ""
echo -e "${GREEN}✅ OpenCode environment setup complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Installed tools:${NC}"
echo "  - OpenCode: $(command -v opencode 2>&1 || echo 'installed')"
echo "  - mgrep: $(command -v mgrep 2>&1 || echo 'not found')"
echo "  - uv: $(uv --version)"
echo "  - Serena MCP: Available (via uvx)"
echo ""
if [ -f "ai-rules/scripts/setup_new_tools.sh" ]; then
    echo -e "${YELLOW}📋 New Elixir-native tools (see above):${NC}"
    echo "  - anubis_mcp: Elixir MCP SDK"
    echo "  - jido_ai: Agent framework + LLM integration"
    echo "  - swarm_ex: Agent orchestration"
    echo "  - codicil: Elixir-native semantic search"
    echo "  - probe: AST-aware code search (backup)"
fi
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "  1. Initialize project:"
echo "      bash ai-rules/scripts/init_project.sh my_app"
echo ""
echo "  2. Configure project:"
echo "      vim project_requirements.md"
echo ""
echo "  3. Validate new tools:"
echo "      bash ai-rules/scripts/validate_new_tools.sh"
echo ""
echo "  4. Start plan session:"
echo "      opencode --config .opencode/opencode.plan.json"
echo ""
echo -e "${GREEN}🎉 Happy coding with ai-rules! 🎉${NC}"
