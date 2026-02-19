# Suggested Commands for ai-rules

## Development Workflow

### Initial Setup
```bash
# Enter Nix development shell
nix develop

# Install dependencies
mix deps.get
cd assets && npm install && cd ..
```

### Code Quality
```bash
# Format code
mix format

# Code quality checks
mix credo --strict

# Type checking (if PLTs available)
mix dialyzer

# Run tests
mix test

# Run tests with coverage
mix test --cover
```

### Test Commands
```bash
# Run all tests
mix test

# Run specific test file
mix test test/path/to/file_test.exs

# Run specific test line
mix test test/path/to/file_test.exs:42

# Run failed tests only
mix test --failed

# Run tests with specific tag
mix test --include live_call
```

### OpenCode Sessions
```bash
# Plan mode (architecture, read-only)
opencode --config .opencode/opencode.plan.json

# Build mode (implementation, TDD)
opencode --config .opencode/opencode.build.json

# Review mode (quality assurance)
opencode --config .opencode/opencode.review.json
```

## Search & Discovery

### Exact Search (ripgrep)
```bash
# Search for exact pattern
rg "def authenticate"

# Search with regex
rg "def handle_*"

# Search specific directory
rg "UserService" lib/
```

### Semantic Search (mgrep)
```bash
# Conceptual search
mgrep "authentication flow pattern"

# Limit results
mgrep "error handling" -m 10

# Search specific directory
mgrep "auth pattern" lib/

# Web search for external patterns
mgrep "OTP GenServer patterns" --web
```

## Tool Setup

### mgrep Setup
```bash
# Install mgrep
npm install -g @mixedbread/mgrep

# Install OpenCode integration
mgrep install-opencode

# Configure authentication
mgrep login

# Start background indexing
mgrep watch &

# Run setup script
bash scripts/setup_mgrep_opencode.sh
```

### Serena MCP Setup
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Test Serena
uvx --from git+https://github.com/oraios/serena serena start-mcp-server --help
```

## Project Initialization

### Create New Project
```bash
# Initialize new project
bash ai-rules/scripts/init_project.sh my_app

# With specific template
bash ai-rules/scripts/init_project.sh my_app ~/path/to/ai-rules phoenix-basic

# Validate requirements
bash ai-rules/scripts/validate_requirements.sh
```

## Git Workflow

### Feature Development
```bash
# Create feature branch
git checkout -b feature/add-feature

# Commit with conventional format
git add .
git commit -m "feat: add new feature"

# Push and create PR
git push -u origin feature/add-feature
gh pr create --title "Add feature" --body "Description..."

# Merge with squash
gh pr merge --squash

# Cleanup
git checkout main
git pull origin main
git branch -d feature/add-feature
```

## Utility Commands

### Check Resources
```bash
# Check tool versions
mix --version
elixir --version
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# Check process count
:erlang.system_info(:process_count)

# Start observer
:observer.start()
```

### Environment Variables
```bash
# Suppress Nix banner
export AI_RULES_SILENT=1

# Run commands in Nix shell
nix develop -c bash -lc 'mix test'
```

## Nix Commands

### Development Shell
```bash
# Enter development shell
nix develop

# Select specific flake
nix develop .#phoenix_ash
nix develop .#universal
nix develop .#nerves

# Run command in shell
nix develop -c bash -lc 'mix test'
```

## Before Using Unfamiliar Tasks
```bash
# Check task options
mix help <task>
```
