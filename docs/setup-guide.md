# ai-rules Setup Guide

This guide covers setting up the ai-rules development environment.

## Quick Start

### Option 1: One-Line Setup

```bash
curl -fsSL https://raw.githubusercontent.com/your-org/ai-rules/main/scripts/setup_all.sh | bash
```

### Option 2: Manual Setup

```bash
git clone https://github.com/your-org/ai-rules.git
cd ai-rules
./scripts/setup_all.sh
```

### Option 3: Docker Setup

```bash
cd tools/setup
docker-compose up -d
docker-compose exec dev bash
```

---

## Requirements

### Required

| Tool | Version | Purpose |
|------|---------|---------|
| Git | 2.30+ | Version control |
| Elixir | 1.14+ | Core language |
| Erlang/OTP | 25+ | BEAM runtime |
| Hex | Latest | Package manager |

### Optional (Recommended)

| Tool | Purpose |
|------|---------|
| asdf | Version management |
| Docker | Containerized environment |
| Node.js | Some tooling |
| Go | mgrep and other tools |

---

## Platform-Specific Instructions

### macOS

```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install git elixir asdf

# Run setup
./scripts/setup_all.sh
```

### Linux (Ubuntu/Debian)

```bash
# Install dependencies
sudo apt update
sudo apt install -y git curl build-essential erlang elixir

# Install asdf (optional)
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc

# Run setup
./scripts/setup_all.sh
```

### Linux (Fedora/RHEL)

```bash
# Install dependencies
sudo dnf install -y git curl erlang elixir

# Run setup
./scripts/setup_all.sh
```

### Windows (WSL2)

```bash
# In WSL2 Ubuntu
curl -fsSL https://raw.githubusercontent.com/your-org/ai-rules/main/scripts/setup_all.sh | bash
```

---

## Manual Installation Steps

### 1. Install Elixir

#### Using asdf (Recommended)

```bash
asdf plugin add erlang
asdf plugin add elixir
asdf install erlang 26.2.1
asdf install elixir 1.16.1-otp-26
asdf global erlang 26.2.1
asdf global elixir 1.16.1-otp-26
```

#### Using Homebrew (macOS)

```bash
brew install elixir
```

#### Using Package Managers

```bash
# Ubuntu/Debian
sudo apt install elixir

# Fedora
sudo dnf install elixir

# Arch Linux
sudo pacman -S elixir
```

### 2. Install Hex and Rebar

```bash
mix local.hex --force
mix local.rebar --force
```

### 3. Install Project Dependencies

```bash
mix deps.get
mix compile
```

### 4. Verify Installation

```bash
./scripts/verify_setup.sh
```

---

## Optional Tools

### Serena (MCP Tool)

```bash
git clone https://github.com/serenalabs/serena.git ~/.local/share/serena
cd ~/.local/share/serena
mix deps.get
mix compile
```

### mgrep (Semantic Search)

```bash
go install github.com/mitchellh/mgrep@latest
```

### OpenCode

```bash
./scripts/setup_opencode.sh
```

---

## Docker Environment

### Building the Container

```bash
cd tools/setup
docker build -t ai-rules-dev .
```

### Running the Container

```bash
# Interactive shell
docker run -it -v $(pwd)/../..:/app ai-rules-dev bash

# Using docker-compose
docker-compose up -d
docker-compose exec dev bash
```

### Common Docker Commands

```bash
# Start services
docker-compose up -d

# Get a shell
docker-compose exec dev bash

# Run tests
docker-compose run --rm test

# Run CI checks
docker-compose run --rm ci

# Stop services
docker-compose down

# Clean up
docker-compose down -v
```

---

## Configuration

### MCP Configuration

For Claude Desktop integration:

```json
// ~/Library/Application Support/Claude/claude_desktop_config.json (macOS)
// ~/.config/claude/claude_desktop_config.json (Linux)

{
  "mcpServers": {
    "serena": {
      "command": "elixir",
      "args": ["--eval", "Serena.MCP.Server.start()"]
    }
  }
}
```

### Git Hooks

Git hooks are installed automatically by `setup_all.sh`. To manually install:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
mix format --check-formatted
mix credo --strict || true
EOF
chmod +x .git/hooks/pre-commit
```

---

## Troubleshooting

### Common Issues

#### Elixir not found

```bash
# Add to shell config
echo 'export PATH="$HOME/.asdf/shims:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Hex installation fails

```bash
mix local.hex --force
```

#### Permission denied

```bash
chmod +x scripts/*.sh
```

#### mix compile fails

```bash
rm -rf _build deps
mix deps.get
mix compile
```

### Verification

Run the verification script to diagnose issues:

```bash
./scripts/verify_setup.sh --verbose
```

---

## Next Steps

After setup is complete:

1. **Verify**: Run `./scripts/verify_setup.sh`
2. **Test**: Run `mix test`
3. **Format**: Run `mix format`
4. **Lint**: Run `mix credo --strict`
5. **Read**: Check `AGENTS.md` for usage instructions

---

## Getting Help

- **Documentation**: See `docs/` directory
- **Issues**: Open an issue on GitHub
- **Chat**: Join the community chat (if available)
