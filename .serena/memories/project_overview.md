# ai-rules Project Overview

## Purpose
ai-rules provides standardized AI agent guidelines, tool configurations, and project templates for building Elixir/BEAM applications with agentic AI tools.

## Key Features
- **Tool-agnostic**: Works with OpenCode, Claude Code, Cursor
- **Subscription-free**: All tools (mgrep, Serena) are open-source
- **Multi-session**: Separate plan, build, review workflows
- **Flexible LLMs**: Local (Ollama, LM Studio, MLX) + API providers
- **Elixir/BEAM focused**: OTP patterns, Domain Resource Action, TDD

## Tech Stack
- Elixir 1.17+ / OTP 26+
- Phoenix framework (web apps)
- Ash framework (domain modeling)
- Nix (optional - reproducible environments)
- OpenCode (primary AI tool)
- mgrep (semantic code search)
- Serena MCP (symbol-aware editing)

## Core Architecture
- **Roles**: Agent personas (Architect, Orchestrator, Reviewer, QA, Specialists)
- **Skills**: Technical modules (OTP patterns, Ecto analysis, testing)
- **Patterns**: Quick-reference code patterns (~600-800 patterns)
- **Templates**: Project templates (Phoenix-Ash-LiveView, Nerves, Library)
- **Configs**: Tool configurations, Nix flakes, LLM configs

## Multi-Session Workflow
1. **Plan Session**: Architecture design (read-only, mgrep discovery)
2. **Build Session**: TDD implementation (Serena + mgrep + write tools)
3. **Review Session**: Quality assurance (read-only, cross-reference)

## Directory Structure
- `roles/`: Agent role definitions
- `skills/`: Technical skill modules
- `patterns/`: Code pattern library
- `tools/`: Tool-specific configurations
- `templates/`: Project templates
- `docs/`: Comprehensive documentation
- `configs/`: Configuration templates
- `scripts/`: Automation scripts
