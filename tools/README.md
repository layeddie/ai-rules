# Tools Configuration

This directory contains tool-specific configurations for integrating `.ai_rules` with various AI agent interfaces.

---

## Overview

`.ai_rules` is designed to be **tool-agnostic** but provides optimized configurations for:
- **OpenCode** (primary) - Multi-session agentic development
- **Claude** (compatible) - Code/Desktop/Code interface
- **Cursor** (compatible) - VS Code-based agentic development
- **Nix** (optional) - Reproducible development environment

---

## Tool-Specific Configurations

### OpenCode (`tools/opencode/`)

**Primary Tool**: OpenCode with multi-session support

**Features**:
- Multi-mode configuration (plan, build, review)
- MCP server integration (Serena)
- Local LLM support (Ollama, LM Studio, MLX)
- mgrep native integration
- Role-based agents per mode

**Configuration Files**:
- `opencode.json` - Base configuration template
- `opencode.plan.json` - Plan mode (read-only, mgrep primary)
- `opencode.build.json` - Build mode (full access, Serena primary)
- `opencode.review.json` - Review mode (analysis, both tools)
- `opencode_mcp.json` - MCP server configuration (Serena)

**See**: `tools/opencode/README.md` for detailed integration guide

### Claude (`tools/claude/`)

**Compatible Tool**: Claude Code / Claude Desktop / Cursor

**Features**:
- `.claude/agents/` - Agent definitions
- `.claude/commands/` - Slash commands
- `.claude/skills/` - Technical skills

**Structure**:
```
.claude/
├── agents/      # Agent definitions (elixir-architect, elixir-tester, etc.)
├── commands/     # Custom commands (/create-feature, /full-test)
└── skills/       # Technical skills (otp-patterns, ecto-query-analysis, etc.)
```

**See**: `tools/claude/README.md` for detailed usage guide

### Cursor (`tools/cursor/`)

**Compatible Tool**: Cursor (VS Code-based AI)

**Features**:
- `.cursorrules` - Cursor rules file
- Role-based prompting
- Agent workflows

**Configuration Files**:
- `.cursorrules` - Cursor-specific rules

**See**: `tools/cursor/README.md` for detailed usage guide

### Nix (`tools/nix/`)

**Optional Tool**: Nix for reproducible development

**Features**:
- Flake-based configuration
- DevShell with all dependencies
- GPU acceleration support (MLX)
- Local LLM path configuration

**Configuration Files**:
- `nix_flake_template.nix` - Nix flake template (created after you provide flake.nix)

**See**: `tools/nix/README.md` for detailed integration guide

---

## Tool Comparison

| Feature | OpenCode | Claude | Cursor | Nix |
|----------|-----------|---------|---------|------|
| **Multi-Session** | ✅ Native | ⚠️ Manual | ⚠️ Manual | ✅ Via terminals |
| **MCP Support** | ✅ Native | ⚠️ Limited | ⚠️ Limited | ❌ N/A |
| **mgrep Integration** | ✅ Native | ⚠️ Manual | ❌ Manual | ❌ N/A |
| **Local LLM** | ✅ Built-in | ✅ Yes | ✅ Yes | ✅ Configuration |
| **Plan/Build/Review** | ✅ Separate configs | ⚠️ Manual | ⚠️ Manual | ✅ Via terminals |
| **Best Fit** | Full-featured dev | Quick coding | VS Code workflows | Dev environment |

---

## Choosing a Tool

### Use OpenCode When:
- You need multi-session workflow (plan/build/review)
- You want native MCP support (Serena)
- You prefer mgrep integration
- You're doing full-featured development

### Use Claude When:
- You prefer Claude interface
- You're familiar with Claude Code/Desktop
- You want to use Claude-specific features

### Use Cursor When:
- You prefer VS Code interface
- You're working with VS Code projects
- You want Cursor-specific features

### Use Nix When:
- You want reproducible development environment
- You need precise dependency control
- You're on Apple Silicon and want GPU optimization

---

## Common Configurations

### LLM Providers

All tools support:
- **Local LLMs**: Ollama, LM Studio, MLX
- **API LLMs**: Anthropic, OpenAI, OpenCode Zen
- **Configuration**: Set in `project_requirements.md`

### Tools

All tools support:
- **mgrep**: Semantic search (native in OpenCode, manual in others)
- **Serena MCP**: Semantic search + edit (via MCP)
- **grep**: Exact pattern matching

### Roles & Skills

All tools use:
- **Roles**: `roles/` directory (architect, orchestrator, etc.)
- **Skills**: `skills/` directory (otp-patterns, ecto-query-analysis, etc.)
- **Configuration**: Project-specific in `project_requirements.md`

---

## Migration Between Tools

### From Claude to OpenCode

1. Copy `.claude/` structure to `.ai_rules/`
2. Create `.opencode/` directory
3. Copy configurations from `tools/opencode/`
4. Update `project_requirements.md` with OpenCode-specific settings
5. Start multi-session workflow

### From Cursor to OpenCode

1. Copy `.cursorrules` to `tools/cursor/`
2. Create `.opencode/` directory
3. Copy configurations from `tools/opencode/`
4. Update `project_requirements.md` with OpenCode-specific settings
5. Start multi-session workflow

### From Nix to OpenCode

1. Keep `flake.nix` for development environment
2. Create `.opencode/` directory
3. Copy configurations from `tools/opencode/`
4. Start OpenCode within Nix shell
5. Follow multi-session workflow

---

## Troubleshooting

### Tool Not Working

**OpenCode**:
- Check `opencode.json` syntax: `opencode validate .opencode/config.json`
- Verify OpenCode installation: `opencode --version`
- Check MCP configuration in `.opencode/mcp.json`

**Claude**:
- Verify `.claude/` structure matches expected format
- Check Claude Code/Desktop settings
- Restart Claude agent

**Cursor**:
- Verify `.cursorrules` file location
- Check Cursor settings for rules loading
- Restart Cursor

**Nix**:
- Check `flake.nix` syntax: `nix flake check`
- Verify dependencies are available in devShell
- Run `nix develop` to enter shell

### Configuration Not Applied

**Symptom**: Tool not using `.ai_rules` configuration

**Solutions**:
1. Check file paths are correct
2. Verify symlinks: `ls -la .ai_rules`
3. Restart tool after configuration changes
4. Check tool documentation for specific setup steps

---

## Documentation Index

- **OpenCode**: `tools/opencode/README.md`
- **Claude**: `tools/claude/README.md`
- **Cursor**: `tools/cursor/README.md`
- **Nix**: `tools/nix/README.md`

---

## Summary

`.ai_rules` supports multiple AI tools with optimized configurations. Choose the tool that best fits your workflow, or use multiple tools together for different aspects of development.

**Primary Tool**: OpenCode (recommended for full-featured Elixir/BEAM development)

**Compatible Tools**: Claude, Cursor, Nix

**Flexible LLM Support**: Local (Ollama, LM Studio, MLX) + API (Anthropic, OpenAI, OpenCode Zen)

**Universal Guidelines**: Roles, skills, and project templates work across all tools
