#!/bin/bash
# ai-rules/scripts/init_project.sh
# Initialize new Elixir project with AI rules

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
PROJECT_NAME=${1}
# Default to parent directory of this script if no path provided
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_RULES_PATH=${2:-"$(cd "$SCRIPT_DIR/.." && pwd)"}
TEMPLATE=${3:-"phoenix-ash-liveview"}

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Usage: $0 <project-name> [ai_rules_path] [template]${NC}"
    echo ""
 echo "Available templates:"
     echo "  - phoenix-ash-liveview (default) - Phoenix + Ash web application"
     echo "  - phoenix-basic - Basic Phoenix application"
     echo "  - elixir-library - Elixir library"
     echo "  - nerves - Nerves embedded systems"
     echo "  - universal - Universal Elixir development"
     exit 1
fi

echo -e "${GREEN}🚀 Initializing Elixir project: $PROJECT_NAME${NC}"
echo -e "${YELLOW}📋 Template: $TEMPLATE${NC}"
echo -e "${YELLOW}🔗 AI Rules: $AI_RULES_PATH${NC}"

# Validate AI rules path
if [ ! -d "$AI_RULES_PATH" ]; then
    echo -e "${RED}Error: AI rules path not found: $AI_RULES_PATH${NC}"
    exit 1
fi

# 1. Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# 2. Initialize git
git init
git branch -M main

# 3. Create symlink to ai-rules
echo -e "${GREEN}🔗 Linking ai-rules...${NC}"
if [ -e ai-rules ]; then
    echo -e "${YELLOW}⚠️  ai-rules already exists, skipping symlink${NC}"
else
    ln -s "$AI_RULES_PATH" ai-rules
fi

# 4. Create project_requirements.md from template
echo -e "${GREEN}📄 Creating project_requirements.md...${NC}"
cp ai-rules/configs/project_requirements.md project_requirements.md

# 5. Create OpenCode configs directory
echo -e "${GREEN}⚙️  Creating OpenCode configuration...${NC}"
mkdir -p .opencode
cp ai-rules/tools/opencode/opencode.json .opencode/config.json
cp ai-rules/tools/opencode/opencode_mcp.json .opencode/mcp.json
cp ai-rules/tools/opencode/opencode.plan.json .opencode/opencode.plan.json
cp ai-rules/tools/opencode/opencode.build.json .opencode/opencode.build.json
cp ai-rules/tools/opencode/opencode.review.json .opencode/opencode.review.json

# 6. Copy template files (if specified)
if [ "$TEMPLATE" != "none" ]; then
    TEMPLATE_PATH="ai-rules/templates/$TEMPLATE"
    if [ -d "$TEMPLATE_PATH" ]; then
        # Check if template has files to copy (excluding README)
        TEMPLATE_FILES=$(find "$TEMPLATE_PATH" -type f ! -name "README.md" ! -name "template_config.json" 2>/dev/null | wc -l | xargs)
        if [ "$TEMPLATE_FILES" -gt 0 ]; then
            echo -e "${GREEN}📋 Applying template: $TEMPLATE${NC}"
            # Copy template files (exclude README and metadata)
            find "$TEMPLATE_PATH" -type f ! -name "README.md" ! -name "template_config.json" -exec cp {} . \;
        else
            echo -e "${YELLOW}⚠️  Template '$TEMPLATE' is a placeholder (no files to copy)${NC}"
            echo -e "${GREEN}✅ Using basic project structure${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Template not found: $TEMPLATE, using basic structure${NC}"
    fi
fi

# 7. Copy appropriate flake.nix based on template
echo -e "${GREEN}📦 Copying Nix flake...${NC}"
case "$TEMPLATE" in
  "nerves")
    cp ai-rules/configs/nix_flake_nerves.nix flake.nix
    echo -e "${GREEN}   Using Nerves flake template${NC}"
    ;;
  "universal")
    cp ai-rules/configs/nix_flake_universal.nix flake.nix
    echo -e "${GREEN}   Using Universal flake template${NC}"
    ;;
  "phoenix-basic"|"elixir-library")
    # For these templates, use universal
    cp ai-rules/configs/nix_flake_universal.nix flake.nix
    echo -e "${GREEN}   Using Universal flake template${NC}"
    ;;
  "phoenix-ash-liveview"|*)
    # Default template uses Phoenix + Ash
    cp ai-rules/configs/nix_flake_phoenix_ash.nix flake.nix
    echo -e "${GREEN}   Using Phoenix + Ash flake template${NC}"
    ;;
esac

# 8. Create basic file structure
echo -e "${GREEN}📁 Creating file structure...${NC}"
mkdir -p {lib,test,config,priv}

# 9. Create .gitignore
echo -e "${GREEN}📝 Creating .gitignore...${NC}"
cat > .gitignore << 'EOF'
# AI rules (symlinked)
ai-rules

# OpenCode
.opencode/
.serena/

# MCP servers
.tidewave/

# Elixir
/_build/
/deps/
*.beam
*.dump
erl_crash.dump

# Environment
.env
*.secret.exs

# IDE
.vscode/
.idea/
.DS_Store

EOF

# 10. Create initial mix.exs if not from template
if [ ! -f mix.exs ]; then
    echo -e "${GREEN}📦 Creating basic mix.exs...${NC}"
    cat > mix.exs << 'EOF'
defmodule ${PROJECT_NAME^}.MixProject do
  use Mix.Project

  def project do
    [
      app: :${PROJECT_NAME},
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {${PROJECT_NAME}.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_view, "~> 1.0.0"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.4"},
      {:gettext, "~> 0.23"},
      {:credo, "~> 1.4", runtime: false}
      {:dialyxir, "~> 1.4", plt_add_apps: [:logger]}
    ]
  end
end
EOF
fi

# 11. Initial git commit
echo -e "${GREEN}💾 Creating initial git commit...${NC}"
git add .
git commit -m "chore: initialize project with ai-rules

- Create project structure
- Link ai-rules repository
- Add OpenCode configuration
- Apply template: $TEMPLATE
- Create .gitignore
- Create initial mix.exs"

# 11. Print success message and next steps
echo ""
echo -e "${GREEN}✅ Project initialized successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "  1. Enter Nix development environment:"
echo "     nix develop"
echo ""
echo "  2. Install Elixir dependencies:"
echo "     mix deps.get"
echo ""
echo "  3. Edit project_requirements.md with your requirements"
echo "     vim project_requirements.md"
echo ""
echo "  2. Start plan session (Terminal 1):"
echo "     opencode --config .opencode/opencode.plan.json"
echo ""
echo "  3. Start build session (Terminal 2):"
echo "     opencode --config .opencode/opencode.build.json"
echo ""
echo "  4. Start review session (Terminal 3, optional):"
echo "     opencode --config .opencode/opencode.review.json"
echo ""
echo -e "${YELLOW}📚 For more information, see:${NC}"
echo "  - ai-rules/PROJECT_INIT.md"
echo "  - ai-rules/README.md"
echo "  - ai-rules/AGENTS.md"
echo ""
echo -e "${GREEN}Happy coding! 🎉${NC}"
