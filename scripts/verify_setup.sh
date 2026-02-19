#!/bin/bash
#
# verify_setup.sh - Verify ai-rules setup is complete
#
# This script checks that all required and optional tools are properly
# installed and configured for the ai-rules project.
#
# Usage: ./scripts/verify_setup.sh [--verbose]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERBOSE=false
CHECK_OPTIONAL=true

for arg in "$@"; do
    case $arg in
        --verbose|-v) VERBOSE=true ;;
        --required-only) CHECK_OPTIONAL=false ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v      Show detailed output"
            echo "  --required-only    Only check required tools"
            echo "  --help, -h         Show this help"
            exit 0
            ;;
    esac
done

# Counters
PASS=0
FAIL=0
WARN=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
    ((WARN++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_command() {
    local cmd=$1
    local version_cmd=${2:-"--version"}
    
    if command -v "$cmd" &> /dev/null; then
        if [ "$VERBOSE" = true ]; then
            local version
            version=$($cmd $version_cmd 2>&1 | head -1) || version="unknown"
            pass "$cmd ($version)"
        else
            pass "$cmd is installed"
        fi
        return 0
    else
        fail "$cmd is not installed"
        return 1
    fi
}

check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        if [ "$VERBOSE" = true ]; then
            pass "$description: $file"
        else
            pass "$description"
        fi
        return 0
    else
        fail "$description: $file not found"
        return 1
    fi
}

check_dir() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
        if [ "$VERBOSE" = true ]; then
            pass "$description: $dir"
        else
            pass "$description"
        fi
        return 0
    else
        warn "$description: $dir not found"
        return 1
    fi
}

# Run verification
echo ""
echo "====================================="
echo "  ai-rules Setup Verification"
echo "====================================="
echo ""

# 1. System Requirements
echo "=== System Requirements ==="

check_command git
check_command curl || check_command wget

echo ""

# 2. Elixir/BEAM Stack
echo "=== Elixir/BEAM Stack ==="

if check_command elixir; then
    if [ "$VERBOSE" = true ]; then
        elixir --version
    fi
fi

check_command mix
check_command iex

# Check Elixir version
if command -v elixir &> /dev/null; then
    ELIXIR_VERSION=$(elixir --version | grep "Elixir" | awk '{print $2}')
    MAJOR=$(echo $ELIXIR_VERSION | cut -d. -f1)
    MINOR=$(echo $ELIXIR_VERSION | cut -d. -f2)
    
    if [ "$MAJOR" -ge 1 ] && [ "$MINOR" -ge 14 ]; then
        pass "Elixir version >= 1.14 ($ELIXIR_VERSION)"
    else
        warn "Elixir version < 1.14 ($ELIXIR_VERSION) - upgrade recommended"
    fi
fi

echo ""

# 3. Project Files
echo "=== Project Files ==="

check_file "mix.exs" "Mix project file"
check_file "AGENTS.md" "Agent instructions"
check_file "README.md" "README"

if [ -f "mix.exs" ]; then
    # Check if deps are compiled
    if [ -d "_build" ]; then
        pass "Dependencies compiled"
    else
        warn "Dependencies not compiled - run 'mix deps.get && mix compile'"
    fi
    
    # Check for lock file
    check_file "mix.lock" "Dependency lock file"
fi

echo ""

# 4. Hex and Rebar
echo "=== Hex and Rebar ==="

if command -v mix &> /dev/null; then
    if mix hex.info &> /dev/null; then
        pass "Hex is installed"
    else
        fail "Hex is not installed - run 'mix local.hex'"
    fi
    
    if [ -f "_build/.mix/rebar3" ] || command -v rebar3 &> /dev/null; then
        pass "Rebar3 is available"
    else
        warn "Rebar3 may not be installed - run 'mix local.rebar'"
    fi
fi

echo ""

# 5. Code Quality Tools (if project has them)
echo "=== Code Quality ==="

if grep -q "credo" mix.exs 2>/dev/null; then
    check_command "mix" "help credo" && pass "Credo is available" || warn "Credo not configured"
fi

if grep -q "dialyxir" mix.exs 2>/dev/null; then
    check_command "mix" "help dialyzer" && pass "Dialyzer is available" || warn "Dialyzer not configured"
fi

if grep -q "excoveralls" mix.exs 2>/dev/null; then
    info "Coverage reporting configured"
fi

echo ""

# 6. Optional Tools
if [ "$CHECK_OPTIONAL" = true ]; then
    echo "=== Optional Tools ==="
    
    # asdf
    if command -v asdf &> /dev/null; then
        pass "asdf is installed"
        if [ "$VERBOSE" = true ]; then
            asdf current
        fi
    else
        warn "asdf not installed (recommended for version management)"
    fi
    
    # Docker
    if command -v docker &> /dev/null; then
        pass "Docker is installed"
        if docker info &> /dev/null; then
            pass "Docker daemon is running"
        else
            warn "Docker daemon not running"
        fi
    else
        info "Docker not installed (optional)"
    fi
    
    # Serena
    if [ -d "$HOME/.local/share/serena" ]; then
        pass "Serena is installed"
    else
        info "Serena not installed (optional - for MCP integration)"
    fi
    
    # mgrep
    if command -v mgrep &> /dev/null; then
        pass "mgrep is installed"
    else
        info "mgrep not installed (optional - for semantic search)"
    fi
    
    # Go (for some tools)
    if command -v go &> /dev/null; then
        pass "Go is installed"
    else
        info "Go not installed (optional - required for some tools)"
    fi
    
    echo ""
    
    # 7. MCP Configuration
    echo "=== MCP Configuration ==="
    
    if [ -f "$HOME/.config/claude/claude_desktop_config.json" ]; then
        pass "MCP config exists"
        if grep -q "serena" "$HOME/.config/claude/claude_desktop_config.json" 2>/dev/null; then
            pass "Serena configured in MCP"
        else
            info "Serena not in MCP config"
        fi
    else
        info "No MCP configuration found"
    fi
    
    echo ""
fi

# 8. Directory Structure
echo "=== Project Structure ==="

check_dir "skills" "Skills directory"
check_dir "patterns" "Patterns directory"
check_dir "docs" "Docs directory"
check_dir "roles" "Roles directory"
check_dir "scripts" "Scripts directory"
check_dir "tools" "Tools directory"

echo ""

# 9. Git Status
echo "=== Git Status ==="

if [ -d ".git" ]; then
    pass "Git repository initialized"
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        warn "Uncommitted changes detected"
        if [ "$VERBOSE" = true ]; then
            git status --short
        fi
    else
        pass "Working tree clean"
    fi
    
    # Check current branch
    BRANCH=$(git branch --show-current)
    info "Current branch: $BRANCH"
    
    # Check remote
    if git remote | grep -q "origin"; then
        pass "Remote 'origin' configured"
    else
        warn "No remote 'origin' configured"
    fi
else
    fail "Not a git repository"
fi

echo ""

# Summary
echo "====================================="
echo "  Summary"
echo "====================================="
echo ""
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo -e "Warnings: ${YELLOW}$WARN${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ Setup verification passed!${NC}"
    echo ""
    echo "You're ready to use ai-rules. Try:"
    echo "  mix test                    # Run tests"
    echo "  mix format                  # Format code"
    echo "  mix credo --strict          # Run linter"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Setup verification failed${NC}"
    echo ""
    echo "Please address the failed checks above and run this script again."
    echo ""
    echo "For help, see:"
    echo "  docs/setup-guide.md"
    echo "  scripts/setup_all.sh"
    echo ""
    exit 1
fi
