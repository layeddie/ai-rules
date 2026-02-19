#!/bin/bash
#
# setup_all.sh - Consolidated setup script for ai-rules
#
# This script sets up all required dependencies and tools for the ai-rules project.
# Run with: ./scripts/setup_all.sh [--skip-optional]
#
# Requirements:
#   - Elixir 1.14+
#   - Erlang/OTP 25+
#   - Git
#   - curl or wget
#
# Optional (for enhanced features):
#   - Docker
#   - Node.js (for some tooling)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_OPTIONAL=false
VERBOSE=false

for arg in "$@"; do
    case $arg in
        --skip-optional)
            SKIP_OPTIONAL=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-optional    Skip optional tool installations"
            echo "  --verbose, -v      Show detailed output"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        if [ "$VERBOSE" = true ]; then
            log_success "$1 is installed: $(command -v "$1")"
        else
            log_success "$1 is installed"
        fi
        return 0
    else
        log_warning "$1 is not installed"
        return 1
    fi
}

install_asdf() {
    log_info "Checking asdf..."
    
    if check_command asdf; then
        return 0
    fi
    
    log_info "Installing asdf..."
    
    if [ -d "$HOME/.asdf" ]; then
        log_info "asdf directory exists, skipping installation"
    else
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
        
        # Add to shell config
        for config in ~/.bashrc ~/.zshrc ~/.bash_profile; do
            if [ -f "$config" ]; then
                if ! grep -q '.asdf/asdf.sh' "$config"; then
                    echo -e '\n# asdf' >> "$config"
                    echo '. "$HOME/.asdf/asdf.sh"' >> "$config"
                    echo 'source "$HOME/.asdf/completions/asdf.bash"' >> "$config" 2>/dev/null || true
                fi
            fi
        done
        
        # Source for current session
        . "$HOME/.asdf/asdf.sh"
    fi
    
    log_success "asdf installed"
}

install_elixir() {
    log_info "Checking Elixir..."
    
    if check_command elixir; then
        log_info "Elixir version: $(elixir --version | grep Elixir)"
        return 0
    fi
    
    log_info "Installing Elixir via asdf..."
    
    # Add plugins
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git 2>/dev/null || true
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git 2>/dev/null || true
    
    # Install Erlang and Elixir
    asdf install erlang 26.2.1
    asdf install elixir 1.16.1-otp-26
    
    # Set global versions
    asdf global erlang 26.2.1
    asdf global elixir 1.16.1-otp-26
    
    log_success "Elixir installed: $(elixir --version | grep Elixir)"
}

install_hex_rebar() {
    log_info "Installing Hex and Rebar..."
    
    mix local.hex --force
    mix local.rebar --force
    
    log_success "Hex and Rebar installed"
}

setup_project() {
    log_info "Setting up project dependencies..."
    
    if [ -f "mix.exs" ]; then
        mix deps.get
        mix compile
        
        log_success "Project dependencies installed"
    else
        log_warning "No mix.exs found, skipping project setup"
    fi
}

install_serena() {
    log_info "Setting up Serena (MCP tool)..."
    
    SERENA_DIR="$HOME/.local/share/serena"
    
    if [ -d "$SERENA_DIR" ]; then
        log_info "Serena directory exists, updating..."
        cd "$SERENA_DIR"
        git pull
    else
        log_info "Installing Serena..."
        mkdir -p "$HOME/.local/share"
        cd "$HOME/.local/share"
        git clone https://github.com/serenalabs/serena.git
        cd serena
    fi
    
    # Build Serena
    if [ -f "mix.exs" ]; then
        mix deps.get
        mix compile
    fi
    
    cd - > /dev/null
    log_success "Serena installed"
}

install_mgrep() {
    log_info "Setting up mgrep..."
    
    MGREP_DIR="$HOME/.local/share/mgrep"
    
    if [ -d "$MGREP_DIR" ]; then
        log_info "mgrep directory exists, skipping"
        return 0
    fi
    
    # mgrep requires Go
    if ! check_command go; then
        log_warning "Go not installed, skipping mgrep. Install Go to use mgrep."
        return 1
    fi
    
    log_info "Installing mgrep..."
    go install github.com/mitchellh/mgrep@latest
    
    log_success "mgrep installed"
}

install_opencode() {
    log_info "Setting up OpenCode..."
    
    OPENCODE_DIR="$HOME/.local/share/opencode"
    
    if [ -d "$OPENCODE_DIR" ]; then
        log_info "OpenCode directory exists, skipping"
        return 0
    fi
    
    # Check for install script
    if [ -f "scripts/setup_opencode.sh" ]; then
        ./scripts/setup_opencode.sh
    else
        log_warning "OpenCode setup script not found, skipping"
    fi
}

configure_mcp() {
    log_info "Configuring MCP settings..."
    
    MCP_CONFIG="$HOME/.config/claude/claude_desktop_config.json"
    
    if [ ! -f "$MCP_CONFIG" ]; then
        mkdir -p "$(dirname "$MCP_CONFIG")"
        
        cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {
    "serena": {
      "command": "elixir",
      "args": ["--eval", "System.put_env(\"SERENA_CONFIG_PATH\", \"~/.config/serena/config.exs\"); Serenade.MCP.Server.start()"]
    }
  }
}
EOF
        
        log_success "MCP configuration created at $MCP_CONFIG"
    else
        log_info "MCP configuration already exists"
    fi
}

setup_git_hooks() {
    log_info "Setting up Git hooks..."
    
    if [ -d ".git" ]; then
        # Create pre-commit hook
        cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for ai-rules
mix format --check-formatted
mix credo --strict || true
EOF
        chmod +x .git/hooks/pre-commit
        
        log_success "Git hooks configured"
    else
        log_warning "Not a Git repository, skipping hooks"
    fi
}

verify_setup() {
    log_info "Verifying setup..."
    
    local all_good=true
    
    # Check required tools
    echo ""
    echo "=== Required Tools ==="
    
    check_command git || all_good=false
    check_command elixir || all_good=false
    check_command mix || all_good=false
    
    echo ""
    echo "=== Optional Tools ==="
    
    if [ "$SKIP_OPTIONAL" = false ]; then
        check_command docker || true
        check_command asdf || true
        check_command go || true
    fi
    
    echo ""
    
    if [ "$all_good" = true ]; then
        log_success "All required tools are installed!"
        echo ""
        echo "Next steps:"
        echo "  1. Run 'mix test' to verify project setup"
        echo "  2. Run './scripts/verify_setup.sh' for detailed verification"
        echo "  3. See docs/setup-guide.md for more information"
    else
        log_error "Some required tools are missing. Please install them and run again."
        exit 1
    fi
}

# Main execution
main() {
    echo ""
    echo "====================================="
    echo "  ai-rules Setup Script"
    echo "====================================="
    echo ""
    
    # Check required system tools
    log_info "Checking system requirements..."
    check_command git || { log_error "Git is required. Please install git."; exit 1; }
    check_command curl || check_command wget || { log_error "curl or wget is required."; exit 1; }
    
    # Install core dependencies
    if [ "$SKIP_OPTIONAL" = false ]; then
        install_asdf
    fi
    
    install_elixir
    install_hex_rebar
    setup_project
    
    # Install optional tools
    if [ "$SKIP_OPTIONAL" = false ]; then
        echo ""
        log_info "Installing optional tools..."
        
        install_serena || true
        install_mgrep || true
        install_opencode || true
        configure_mcp || true
    fi
    
    # Configure project
    setup_git_hooks
    
    # Verify
    verify_setup
    
    echo ""
    log_success "Setup complete!"
    echo ""
}

main "$@"
