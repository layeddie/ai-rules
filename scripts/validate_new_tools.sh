#!/bin/bash
# ai-rules/scripts/validate_new_tools.sh
# Validate new tool installations and configurations

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔍 Validating new tool installations...${NC}"

errors=0

# Check Elixir version
elixir_version=$(elixir --version | grep -oE '[0-9.]+(\.[0-9]+)+')
if [[ $(echo "$elixir_version < 1.17.0" | bc -l 2>/dev/null) -eq 1 ]]; then
    echo -e "${RED}❌ Elixir version must be >= 1.17.0 (found: $elixir_version)${NC}"
    ((errors++))
else
    echo -e "${GREEN}✅ Elixir version: $elixir_version${NC}"
fi

# Check Node.js version (for Probe)
if command -v node &> /dev/null; then
    node_version=$(node --version | grep -oE 'v[0-9.]+')
    echo -e "${GREEN}✅ Node.js version: $node_version${NC}"
else
    echo -e "${YELLOW}⚠️  Node.js not found (optional for Probe)${NC}"
fi

# Check tool availability
echo ""
echo "Checking tool availability:"

# Check anubis_mcp
if mix help | grep -q "anubis_mcp" 2>/dev/null; then
    echo -e "${GREEN}✅ anubis_mcp available${NC}"
else
    echo -e "${YELLOW}⚠️  anubis_mcp not in dependencies${NC}"
    ((errors++))
fi

# Check jido_ai
if mix help | grep -q "jido_ai" 2>/dev/null; then
    echo -e "${GREEN}✅ jido_ai available${NC}"
else
    echo -e "${YELLOW}⚠️  jido_ai not in dependencies${NC}"
    ((errors++))
fi

# Check swarm_ex
if mix help | grep -q "swarm_ex" 2>/dev/null; then
    echo -e "${GREEN}✅ swarm_ex available${NC}"
else
    echo -e "${YELLOW}⚠️  swarm_ex not in dependencies${NC}"
    ((errors++))
fi

# Check codicil
if mix help | grep -q "codicil" 2>/dev/null; then
    echo -e "${GREEN}✅ codicil available${NC}"
else
    echo -e "${YELLOW}⚠️  codicil not in dependencies${NC}"
    ((errors++))
fi

# Check Probe
if command -v probe &> /dev/null; then
    echo -e "${GREEN}✅ Probe available${NC}"
else
    echo -e "${YELLOW}⚠️  Probe not installed${NC}"
    ((errors++))
fi

# Check environment variables
echo ""
echo "Checking environment variables:"

env_errors=0

# Check ANTHROPIC_API_KEY (for jido_ai and codicil)
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  ANTHROPIC_API_KEY not set${NC}"
    ((env_errors++))
else
    echo -e "${GREEN}✅ ANTHROPIC_API_KEY set${NC}"
fi

# Check OPENAI_API_KEY (for jido_ai, codicil)
if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  OPENAI_API_KEY not set${NC}"
    ((env_errors++))
else
    echo -e "${GREEN}✅ OPENAI_API_KEY set${NC}"
fi

# Check GOOGLE_API_KEY (for jido_ai)
if [ -z "$GOOGLE_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  GOOGLE_API_KEY not set${NC}"
    ((env_errors++))
else
    echo -e "${GREEN}✅ GOOGLE_API_KEY set${NC}"
fi

# Check CODICIL_LLM_PROVIDER (for codicil)
if [ -z "$CODICIL_LLM_PROVIDER" ]; then
    echo -e "${YELLOW}⚠️  CODICIL_LLM_PROVIDER not set${NC}"
    ((env_errors++))
else
    echo -e "${GREEN}✅ CODICIL_LLM_PROVIDER set${NC}"
fi

# Check ANUBIS_TRANSPORT (for anubis_mcp)
if [ -z "$ANUBIS_TRANSPORT" ]; then
    echo -e "${YELLOW}⚠️  ANUBIS_TRANSPORT not set${NC}"
    ((env_errors++))
else
    echo -e "${GREEN}✅ ANUBIS_TRANSPORT set${NC}"
fi

# Summary
echo ""
if [ $errors -eq 0 ] && [ $env_errors -eq 0 ]; then
    echo -e "${GREEN}✅ All tools validated successfully!${NC}"
    exit 0
else
    if [ $errors -gt 0 ]; then
        echo -e "${RED}❌ Found $errors tool installation issue(s)${NC}"
    fi
    if [ $env_errors -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $env_errors environment variable issue(s)${NC}"
    fi
    exit 1
fi
