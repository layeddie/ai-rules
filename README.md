# ai-rules

**Standards-based AI rules for Elixir/BEAM development**

This repository provides a standardized set of AI agent guidelines, tool configurations, and project templates for building Elixir/BEAM applications with agentic AI tools.

# Disclaimer

This project is provided as-is and without any warranty. The authors are not responsible for any damages or losses resulting from the use of this project.
Created with opencode using GLM 4.7 Zen and research on many elixir ai projects as of Jan 2026. Not fully tested against any real projects yet.

---

## 🎯 Objective

Create a **subscription-free**, standards-based starting point for Elixir/BEAM projects that works with:

- OpenCode (primary tool) - Multi-session agentic development
- Compatible tools (Claude Code, Cursor)
- Local LLMs (Ollama, LM Studio, MLX for Apple Silicon)
- MCP support (Serena)

**Key Principles**:

- Tool-agnostic: Guidelines work across OpenCode, Claude, Cursor
- Subscription-free: All tools (mgrep, Serena) are open-source and free
- Multi-session: Separate plan, build, and review workflows
- Flexible LLMs: Support for local + API providers
- Elixir/BEAM focused: OTP patterns, Domain Resource Action, TDD

---

## 📁 Directory Structure (AI-Search Friendly, Single Responsibility)

```
.
├── ai-rules/               # This repo (symlink in generated projects)
├── .opencode/              # Plan/Build/Review configs
├── config/                 # Environment config only (no business logic)
├── lib/
│   ├── [app]/              # Elixir runtime entry + supervision
│   │   ├── application.ex  # Top-level supervisor
│   │   ├── registry/       # Registry + DynamicSupervisor
│   │   └── support/        # Pure helpers (no IO/side effects)
│   └── [app]_ash/          # Ash Domain Resource Action (Elixir‑Scribe style)
│       ├── domains/        # Domain boundaries
│       │   └── accounts/
│       │       ├── resources/      # Ash Resources (schema + validations)
│       │       ├── actions/        # Ash Actions (single responsibility)
│       │       ├── policies/       # Authorization per resource
│       │       └── notifiers/      # Side-effect handlers (email, pubsub)
│       └── apis/            # Ash APIs that expose resources per domain
├── lib/[app]_web/          # Phoenix LiveView (thin controllers, state in Ash)
│   ├── endpoint.ex
│   ├── router.ex
│   ├── live/               # LiveViews / components
│   └── controllers/        # Minimal glue, delegate to Ash actions
├── priv/repo/              # Migrations & seeds
├── test/                   # Mirrors lib/ for easy grep & coverage
│   ├── support/            # DataCase/ConnCase factories
│   ├── ash/                # Resource/action tests (unit, property-based)
│   └── web/                # LiveView/Controller integration tests
├── flake.nix               # Nix devshell (phoenix_ash/universal/nerves)
└── project_requirements.md # Project + model/tool choices
```

**Why this layout?**
- Single Responsibility: Ash resources/actions/policies separated; controllers stay thin.
- Searchable: Domains/resources/actions live under predictable paths for mgrep/rg.
- Testable: `test/` mirrors `lib/` so coverage tools and agents find pairs quickly.

---

## 🚀 Quick Start

```bash
# Clone or symlink ai-rules into your project
cd my_new_project
ln -s ~/path/to/ai-rules ai-rules

# Initialize project
bash ai-rules/scripts/init_project.sh my_app

# Start plan session (Terminal 1)
opencode --config .opencode/opencode.plan.json

# Start build session (Terminal 2)
opencode --config .opencode/opencode.build.json
```

---

## 📋 Supported Tools

### OpenCode (Primary)

- **Multi-Session**: Plan, build, review workflows
- **MCP Support**: Serena MCP integration
- **mgrep Integration**: Native semantic search
- **Local LLMs**: Ollama, LM Studio, MLX for Apple Silicon

### Compatible Tools

- **Claude**: Full agent, skills, commands support
- **Cursor**: .cursorrules-based prompting

---

## 🎯 Elixir/BEAM Focus

- **OTP Patterns**: GenServer, Supervisor, Application, Registry
- **Domain Resource Action**: Organizes business logic into domains, resources, and actions
- **TDD Workflow**: Red-Green-Refactor cycle
- **Code Quality**: Credo, Dialyzer, formatting, type specs

---

## 🔧 Git Workflow

This project follows a strict Git workflow defined in `git_rules.md`:

- **Feature branch development**: Create branches for all changes
- **Pull requests for code review**: Use PRs for review before merging
- **Conventional commit messages**: Standardized commit format
- **Squash merging**: Clean history on main branch

### Git Roles & Skills

- **Git Specialist Role** (`roles/git-specialist.md`): Git and GitHub workflow expert
- **Git Workflow Skill** (`skills/git-workflow/SKILL.md`): Git automation and best practices

### Key Commands

```bash
# Create feature branch
git checkout -b feature/add-git-workflow

# Commit with conventional format
git add .
git commit -m "feat: add git workflow integration"

# Push and create PR
git push -u origin feature/add-git-workflow
gh pr create --title "Add git workflow" --body "Description..."

# Merge with squash
gh pr merge --squash

# Cleanup branches
git checkout main
git pull origin main
git branch -d feature/add-git-workflow
```

### Repositories

- **ai-rules**: https://github.com/layeddie/ai-rules
- **tensioner**: https://github.com/layeddie/tensioner

For detailed Git workflow rules, see `git_rules.md`.

---

## 🔧 Configuration

### OpenCode

- **Base config**: `tools/opencode/opencode.json`
- **Mode-specific**: Plan, build, review configs
- **MCP config**: `tools/opencode/opencode_mcp.json` (Serena)

### Claude

Compatible

- **Structure**: `.claude/` folder
- **Agents**: Role-based agents
- **Commands**: Slash commands (`/create-feature`, `/full-test`)
- **Skills**: Technical skills

### Cursor

- **Rules file**: `tools/cursor/.cursorrules` with agent prompts

### Nix (Optional)

- **Flake template**: `configs/nix_flake_template.nix`
- **Integration**: MLX GPU support for M2 Max

---

## 📚 Roles

### Architecture & Planning

- **Architect** - System design, OTP supervision trees, domain boundaries
- **Orchestrator** - Implementation coordination, TDD workflow

### Domain-Specific

- **Backend Specialist** - API design, business logic, Ash resources
- **Frontend Specialist** - LiveView UI, real-time features
- **Database Architect** - Ecto schemas, query optimization, N+1 prevention

### Quality Assurance

- **QA** - Testing strategy, coverage analysis, property-based testing
- **Reviewer** - Code review, OTP best practices verification

---

## 🛠️ Technical Skills

### OTP Patterns

- **GenServer patterns** - Client/server separation, named processes
- **Supervisor strategies** - One-for-one, one-for-all, dynamic
- **Registry usage** - Dynamic process naming and discovery

### Ecto Query Analysis

- **N+1 prevention** - Preloading strategies, missing indexes, query optimization

### Test Generation

- **TDD workflow** - ExUnit, property-based testing (StreamData, PropCheck)

---

## 📋 Project Templates

### Phoenix + Ash + LiveView (Primary)

- Complete Phoenix web application
- Ash framework for domain modeling
- LiveView for real-time UI
- User authentication with Ash
- JSON API via Ash JSON API
- Real-time features via Phoenix PubSub

### Phoenix Basic (Stater)

- Basic Phoenix app
- Simple router and controller structure

### Elixir Library (Stater)

- OTP library with public API
- Clean module organization

### Nerves (Stater)

- Embedded Elixir for IoT devices
- Hardware-specific configurations

---

## ⚙️ Scripts

### init_project.sh

- **Purpose**: Initialize new Elixir project with AI rules
- **Functionality**: Creates directory structure, symlinks ai-rules, creates configs, generates .gitignore

### setup_opencode.sh

- **Purpose**: Setup OpenCode environment
- Installs mgrep, uv, Serena MCP
- **Functionality**: Validates all tools are available

### validate_requirements.sh

- **Purpose**: Validates project setup and requirements
- **Functionality**: Checks LLM config, Nix setup, dependencies, and OpenCode configs

---

## 🔨 Configuration Templates

### project_requirements.md

- **Purpose**: Template for defining project requirements
- **Sections**: LLM configuration, tool config, architecture, testing strategy

### opencode_mcp.json

- **Purpose**: MCP server configuration (Serena, placeholder for Tidewave)

### mlx_gpu_config.yml

- **Purpose**: MLX GPU optimization for Apple Silicon M2 Max
- **Hardware**: 64GB RAM, 50GB VRAM, up to 5 GPUs

---

## 🎉 Best Practices

### OTP Principles

- Supervision trees with clear hierarchies
- Domain Resource Action pattern for business logic
- TDD workflow (Red, Green, Refactor)
- Code quality (Credo, Dialyzer, formatting)

### Anti-Patterns

- Blocking GenServer callbacks, mixing concerns, ignoring supervision strategies

---

## 🔗 Subscription-Free

All tools (mgrep, Serena) are open-source and free.

- No subscription required to use `ai-rules`.
- Local LLM providers (Ollama, LM Studio, MLX) are free.
- API providers (Anthropic, OpenAI, OpenCode Zen) are optional, user choice.

---

## 📖 Documentation

### Comprehensive guides for:

- Project initialization
- Tool-specific configurations
- Role definitions
- Technical skills
- Project templates
- Multi-session workflow
- Hardware optimization

---

## 🚀 Starting Point for New Elixir/BEAM Projects

**Use**: `ai-rules` as subscription-free starting point for:

- Standardized project structure
- Multi-session development workflow
- Comprehensive agent guidelines
- Tool integration (mgrep + Serena)
- Flexible LLM support (local + API)
- Elixir/BEAM best practices

**Perfect for**: Full-stack web applications, libraries, or embedded systems!

---

**Ready to code with ai-rules! 🎉**
