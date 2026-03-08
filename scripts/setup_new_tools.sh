#!/bin/bash
# ai-rules/scripts/setup_new_tools.sh
# Setup script for new Elixir-native tools

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}📦 Setting up new Elixir-native tools...${NC}"

# Check OpenCode installation
if ! command -v opencode &> /dev/null; then
    echo -e "${RED}❌ OpenCode not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ OpenCode found${NC}"

# Check new tool dependencies
echo ""
echo -e "${YELLOW}📦 Checking tool dependencies...${NC}"

errors=0

# Check anubis_mcp
if mix help | grep -q "anubis_mcp" 2>/dev/null; then
    echo -e "${GREEN}✅ anubis_mcp already in mix.exs${NC}"
else
    echo -e "${YELLOW}⚠️  anubis_mcp not in mix.exs${NC}"
    echo "  Add to mix.exs: {:anubis_mcp, \"~> 0.17.0\"}"
    ((errors++))
fi

# Check jido_ai
if mix help | grep -q "jido_ai" 2>/dev/null; then
    echo -e "${GREEN}✅ jido_ai already in mix.exs${NC}"
else
    echo -e "${YELLOW}⚠️  jido_ai not in mix.exs${NC}"
    echo "Add to mix.exs: {:jido_ai, \"~> 0.5.3\"}"
    ((errors++))
fi

# Check swarm_ex
if mix help | grep -q "swarm_ex" 2>/dev/null; then
    echo -e "${GREEN}✅ swarm_ex already in mix.exs${NC}"
else
    echo -e "${YELLOW}⚠️  swarm_ex not in mix.exs${NC}"
    echo "Add to mix.exs: {:swarm_ex, \"~> 0.2.0\"}"
    ((errors++))
fi

# Check codicil
if mix help | grep -q "codicil" 2>/dev/null; then
    echo -e "${GREEN}✅ codicil already in mix.exs${NC}"
else
    echo -e "${YELLOW}⚠️  codicil not in mix.exs${NC}"
    echo "Add to mix.exs: {:codicil, \"~> 0.7\", only: [:dev, :test]}"
    ((errors++))
fi

# Check Probe (npx-based)
if command -v probe &> /dev/null; then
    echo -e "${GREEN}✅ Probe available (via npx)${NC}"
else
    echo -e "${YELLOW}⚠️  Probe not installed${NC}"
    echo "Install: npm install -g @buger/probe-mcp@latest"
    ((errors++))
fi

echo ""
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✅ All tools checked successfully!${NC}"
else
    echo -e "${RED}❌ Found $errors issue(s)${NC}"
    echo -e "${YELLOW}Check error messages above${NC}"
fi

echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo " 1. Add dependencies to your project's mix.exs:"
echo "   - Anubis MCP: {:anubis_mcp, \"~> 0.17.0\"}"
echo "   - Jido AI: {:jido_ai, \"~> 0.5.3\"}"
echo "   - Swarm Ex: {:swarm_ex, \"~> 0.2.0\"}"
echo "   - Codicil: {:codicil, \"~> 0.7\", only: [:dev, :test]}"
echo "   - Probe: npm install -g @buger/probe-mcp@latest"
echo ""
echo " 2. Run: mix deps.get"
echo "   - This will install all 5 tools and their dependencies"
echo ""
echo -e "${YELLOW}📚 Documentation:${NC}"
echo " - Tool-specific SKILL.md files for setup instructions:"
echo "   - tools/NEW_TOOLS_GUIDE.md (comprehensive overview)"
echo "   - skills/anubis-mcp/SKILL.md (MCP SDK setup)"
echo "   - skills/jido_ai/SKILL.md (agent framework + LLM integration)"
echo "   - skills/swarm-ex/SKILL.md (agent orchestration)"
echo "   - skills/codicil/SKILL.md (semantic search)"
echo "   - skills/probe/SKILL.md (AST-aware search - backup)"
echo ""
echo -e "${GREEN}🔧 Configure environment variables:${NC}"
echo " - Anubis MCP: export ANUBIS_TRANSPORT=\"streamable_http\""
echo " - Jido AI: export ANTHROPIC_API_KEY=your_key or OPENAI_API_KEY=your_key"
echo " - Swarm Ex: export SWARM_ENV=\"dev\""
echo " - Codicil: export CODICIL_LLM_PROVIDER=openai, export OPENAI_API_KEY=your_key"
echo " - Codicil (optional): export CODICIL_EMBEDDING_PROVIDER=openai, export VOYAGE_API_KEY=your_key"
echo ""
echo -e "${YELLOW}📝 Update opencode_mcp.json:${NC}"
echo "   - New tools will be available after configuration"
echo "   - See tools/NEW_TOOLS_GUIDE.md for usage examples"
echo ""
echo -e "${GREEN}✅ New tools setup complete!${NC}"
echo -e "${YELLOW}📚 Documentation: tools/README.md for integration overview${NC}"
echo ""
echo -e "${GREEN}ai-rules tool setup complete.${NC}"
