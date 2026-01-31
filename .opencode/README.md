# OpenCode Configuration Directory

This directory contains OpenCode configuration files and helper scripts for managing models and modes.

## Quick Start

```bash
# List available models from both Ollama and LM Studio
./.opencode/list-models

# Switch to a different model (interactive)
./.opencode/models

# Switch OpenCode mode (Plan/Build/Review)
cd ~/.config/opencode && ./mode_switch.sh [plan|build|review]
```

## Configuration Files

### Main Configuration
- **opencode.json** - Main OpenCode configuration
- **opencode.plan.json** - Plan mode configuration (read-only architecture design)
- **opencode.build.json** - Build mode configuration (full implementation capability)
- **opencode.review.json** - Review mode configuration (code quality analysis)

### MCP Configuration
- **opencode_mcp.json** - MCP (Model Context Protocol) server configuration

## Helper Scripts

### Model Management

#### `list-models`
List all available models from Ollama and LM Studio.

```bash
./.opencode/list-models
```

**Output**:
- Shows which providers are running
- Lists all available models from each provider
- Indicates if a provider is not running

#### `models`
Interactive model switcher. Lets you:
1. Choose between Ollama and LM Studio
2. Select a specific model
3. Automatically update all configuration files

```bash
./.opencode/models
```

**What it does**:
- Checks if Ollama and/or LM Studio are running
- Shows available models from running providers
- Prompts you to select a provider and model
- Updates all OpenCode configuration files with your selection

### Testing

#### `test_lmstudio.sh`
Test LM Studio connectivity and API functionality.

```bash
./.opencode/test_lmstudio.sh
```

**Tests**:
- LM Studio connectivity
- Available models
- OpenCode configuration
- Mode configurations
- API functionality

## Mode Switching

Mode switching is handled by scripts in `~/.config/opencode/`:

```bash
cd ~/.config/opencode
./mode_switch.sh plan    # Read-only architecture design
./mode_switch.sh build   # Full implementation capability
./mode_switch.sh review  # Code quality analysis
```

### Mode Differences

| Mode | Write | Edit | Bash | Purpose |
|------|-------|------|------|---------|
| Plan | ❌ | ❌ | ❌ | Architecture and design |
| Build | ✅ | ✅ | ✅ | Implementation and coding |
| Review | ❌ | ❌ | ✅ | Code quality analysis |

## Model Providers

### Ollama
- **URL**: http://localhost:11434
- **Start**: `ollama serve`
- **Models**: qwen3-coder, gpt-oss, deepseek-r1, llama3.2, etc.

### LM Studio
- **URL**: http://localhost:1234
- **Start**: `lms server start`
- **Models**: qwen/qwen3-coder-30b, codestral, glm-4.7-flash, etc.

## Configuration Structure

### Example Configuration

```json
{
  "model": {
    "provider": "lmstudio",
    "base_url": "http://localhost:1234",
    "model": "qwen/qwen3-coder-30b",
    "api_key": "lmstudio",
    "temperature": 0.3,
    "max_tokens": 4096,
    "timeout": 30
  },
  "tools": {
    "write": true,
    "edit": true,
    "bash": true,
    "read": true,
    "grep": true,
    "glob": true,
    "webfetch": true,
    "websearch": true
  },
  "mcp": {
    "serena": {
      "type": "local",
      "command": ["uvx", "--from", "git+https://github.com/oraios/serena", "serena", "start-mcp-server"],
      "enabled": true,
      "environment": {
        "SERENA_PROJECT_PATH": "{project_root}/.serena",
        "SERENA_READ_ONLY": "false"
      }
    }
  },
  "permission": {
    "write": "ask",
    "bash": "ask",
    "edit": "ask"
  }
}
```

## Common Workflows

### Workflow 1: Switch to Ollama for coding

```bash
# 1. List available models
./.opencode/list-models

# 2. Switch to Ollama's qwen3-coder
./.opencode/models
# Select: 1) Ollama
# Select: 1) qwen3-coder:30b

# 3. Switch to Build mode
cd ~/.config/opencode
./mode_switch.sh build

# 4. Use OpenCode
```

### Workflow 2: Switch to LM Studio for review

```bash
# 1. Switch to LM Studio's codestral
./.opencode/models
# Select: 2) LM Studio
# Select: 4) mistralai/codestral-22b-v0.1

# 2. Switch to Review mode
cd ~/.config/opencode
./mode_switch.sh review

# 3. Use OpenCode for code review
```

### Workflow 3: Test configuration

```bash
# Test LM Studio
./.opencode/test_lmstudio.sh

# List models
./.opencode/list-models

# Check current config
cat .opencode/opencode.json | grep -A 6 '"model"'
```

## Troubleshooting

### Provider not running

```bash
# Check Ollama
curl http://localhost:11434/api/tags

# Check LM Studio
curl http://localhost:1234/v1/models

# Start if needed
ollama serve          # Start Ollama
lms server start      # Start LM Studio
```

### Configuration not updating

```bash
# Check file permissions
ls -la .opencode/*.json

# Verify script is executable
ls -la .opencode/models
chmod +x .opencode/models
```

### Model not found

```bash
# List available models
./.opencode/list-models

# Verify model name matches exactly
# Some models have version tags like :latest or :30b
```

## Documentation

- **MODEL_SWITCHING.md** - Detailed guide for switching models
- **LM_STUDIO_COMPLETE.md** - LM Studio migration documentation
- **LM_STUDIO_MIGRATION.md** - Migration guide from Ollama to LM Studio

## Support

For issues or questions:

1. Check provider status: `./.opencode/list-models`
2. Test connectivity: `./.opencode/test_lmstudio.sh`
3. Verify configuration: `cat .opencode/opencode.json`
4. Check provider documentation:
   - Ollama: https://ollama.com/docs
   - LM Studio: https://lmstudio.ai/docs

---

**Last Updated**: 2026-01-30
**Supported Providers**: Ollama, LM Studio
**Total Available Models**: 15 (7 from Ollama, 8 from LM Studio)