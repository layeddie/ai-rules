#!/bin/bash
# ai-rules/scripts/validate_requirements.sh
# Validate project setup and requirements

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ROOT=$(pwd)

echo -e "${GREEN}🔍 Validating project setup...${NC}"

# Check for ai-rules symlink
if [ ! -e ai-rules" ]; then
    echo -e "${RED}❌ ai-rules not found (should be symlinked)${NC}"
    exit 1
fi

# Check for project_requirements.md
if [ ! -f "project_requirements.md" ]; then
    echo -e "${RED}❌ project_requirements.md not found${NC}"
    exit 1
fi

# Check for OpenCode configs
if [ ! -d ".opencode" ]; then
    echo -e "${RED}❌ .opencode directory not found${NC}"
    exit 1
fi

# Check for mix.exs
if [ ! -f "mix.exs" ]; then
    echo -e "${YELLOW}⚠️  mix.exs not found, using default template${NC}"
    echo -e "${GREEN}✅ This is OK for template projects${NC}"
fi

# Check for lib/ directory
if [ ! -d "lib" ]; then
    echo -e "${YELLOW}⚠️  lib/ directory not found${NC}"
    echo -e "${GREEN}✅ This is OK for template projects${NC}"
fi

# Check for test/ directory
if [ ! -d "test" ]; then
    echo -e "${YELLOW}⚠️  /test directory not found${NC}"
    echo -e "${GREEN}✅ This is OK for template projects${NC}"
fi

# Validate LLM configuration (if specified)
if grep -q "LLM Configuration" project_requirements.md; then
    echo -e "${GREEN}✅ LLM configuration section found${NC}"
else
    echo -e "${YELLOW}⚠️ LLM configuration section not found (optional)${NC}"
fi

# Validate tool configuration
if grep -q "Tool Configuration" project_requirements.md; then
    echo -e "${GREEN}✅ Tool configuration section found${NC}"
else
    echo -e "${YELLOW}⚠️ Tool configuration section not found (optional)${NC}"
fi

# Check for Nix (if applicable)
if [ -f "flake.nix" ]; then
    echo -e "${GREEN}✅ Nix flake found${NC}"
else
    echo -e "${YELLOW}⚠️ Nix flake not found (optional)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Project validation complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Ready to start development:${NC}"
echo "  1. Edit project_requirements.md with your requirements"
echo "  2. Start plan session (Terminal 1):"
echo "     opencode --config .opencode/opencode.plan.json"
echo ""
echo "  3. Start build session (Terminal 2):"
echo "     opencode --config .opencode/opencode.build.json"
echo ""
echo "  4. Start review session (Terminal 3, optional):"
echo "     opencode --config .opencode/opencode.review.json"
