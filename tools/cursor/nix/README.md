# Nix Integration Guide

This guide explains how to use `ai-rules` with Nix for reproducible Elixir/BEAM development.

---

## Overview

Nix provides **reproducible development environments** for Elixir/BEAM projects. `ai-rules` integrates with Nix to provide:

- **Reproducible Dependencies**: Elixir, OTP, Erlang, Node.js versions pinned
- **Local LLM Paths**: Configured paths to Ollama, LM Studio
- **GPU Acceleration**: MLX support for Apple Silicon (M2 Max)
- **DevShell**: All dependencies available in isolated shell

---

## Prerequisites

### Required Software

#### 1. Nix
```bash
# Check Nix version (must be 2.0+)
nix --version

# Install if needed (macOS/Linux)
curl -L https://nixos.org/nix/install | sh

# On macOS, add to PATH (if not already)
# Add to ~/.zshrc or ~/.bash_profile:
# . "$HOME/.nix-profile/etc/profile.d/nix.sh"
```

#### 2. flakes (if using flakes)
```bash
# Flakes are enabled by default in Nix 2.13+
# Check if enabled
nix flake check

# If not using flakes, enable:
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

### Optional Software

#### 1. direnv (Recommended)
```bash
# Install for automatic flake.nix loading
nix profile install nixpkgs#direnv

# Add to shell (bash/zsh)
# For bash: echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
# For zsh: echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

---

## Nix Flake Templates

### Available Templates

`ai-rules` provides **three production-ready flake.nix templates** for different Elixir use cases:

| Template | Use Case | Description |
|----------|-----------|-------------|
| **`nix_flake_universal.nix`** | General Elixir Development | Elixir, Phoenix, LiveView, Ash, Livebook, PostgreSQL |
| **`nix_flake_phoenix_ash.nix`** | Phoenix + Ash Web Apps | Optimized for Phoenix LiveView with Ash framework |
| **`nix_flake_nerves.nix`** | Embedded Systems | Firmware development with Nerves framework |

### Quick Start

Choose and copy the appropriate template for your project:

```bash
# Universal template (all Elixir projects)
cp ai-rules/configs/nix_flake_universal.nix flake.nix

# Phoenix + Ash template (web applications)
cp ai-rules/configs/nix_flake_phoenix_ash.nix flake.nix

# Nerves template (embedded systems)
cp ai-rules/configs/nix_flake_nerves.nix flake.nix

# Or use init_project.sh (automatically selects appropriate template)
bash ai-rules/scripts/init_project.sh my_app phoenix-ash
```

### Template Details

#### Universal Template (`nix_flake_universal.nix`)

**Use for**: Any Elixir project including Phoenix, LiveView, Ash, Livebook

**Dependencies**:
- Elixir 1.17 + Erlang 27
- PostgreSQL 16 (server + client)
- Node.js 20 (Phoenix assets)
- Git, pkg-config, openssl
- File watchers (fswatch on macOS, inotify on Linux)

**Includes**:
- Ash and Livebook support (via Mix)
- PostgreSQL server for local development
- LiveView hot reload helpers
- Platform-specific dependencies

**Start shell**:
```bash
nix develop
# Then:
mix phx.server    # Phoenix
mix livebook      # Livebook
```

#### Phoenix + Ash Template (`nix_flake_phoenix_ash.nix`)

**Use for**: Web applications using Phoenix LiveView with Ash framework

**Dependencies**: All from Universal template, plus:

**Additional features**:
- Ash formatter configuration notes
- Phoenix LiveView file watching optimizations
- Ash-specific environment variables
- Ash resource generation helpers

**Start shell**:
```bash
nix develop
# Then:
mix ash.gen.resource    # Generate Ash resource
mix phx.gen.resource  # Generate Phoenix resource
mix phx.server        # Start Phoenix
```

#### Nerves Template (`nix_flake_nerves.nix`)

**Use for**: Embedded systems and firmware development with Nerves

**Dependencies**:
- Elixir 1.17 + Erlang 27
- `fwup` - Firmware update utility
- `squashfsTools` - Firmware image creation
- `autoconf`, `automake` - Native NIF compilation
- `x11_ssh_askpass` - Firmware burning password helper
- PostgreSQL 16 (for testing)

**Includes**:
- Firmware building and burning support
- Cross-compilation target support (rpi3, rpi4, bbb, etc.)
- Nerves-specific shell hooks
- Platform-specific frameworks (CoreFoundation/CoreServices on macOS)

**Start shell**:
```bash
nix develop
# Then:
mix firmware         # Build firmware
mix firmware.burn   # Flash to SD card
export MIX_TARGET=rpi3  # Cross-compile for Raspberry Pi 3
```

---

## Nix Configuration

### Basic flake.nix Structure

A minimal flake.nix for Elixir development:

```nix
{
  description = "My Elixir Application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      inherit (nixpkgs) lib;
      inherit (flake-utils.lib) flake-utils;
    in
    {
      devShells.default = nixpkgs.mkShell {
        buildInputs = with pkgs; [
          pkgs.elixir_1_17
          pkgs.beamPackages.erlang_27
          pkgs.postgresql_16
          pkgs.nodejs_22
          pkgs.git
        ];

        shellHook = ''
          # Mix configuration
          export MIX_ENV="dev"
          export HEX_HOME="$PWD/.hex"
          export MIX_ARCHIVES="$PWD/.mix/archives"

          # Node.js configuration (for Phoenix assets)
          export NODE_PATH="$PWD/node_modules"
          export PATH="$PWD/node_modules/.bin:$PATH"

          # Git configuration
          export GIT_AUTHOR_NAME="Your Name"
          export GIT_AUTHOR_EMAIL="your.email@example.com"
        '';

        # Run project-specific setup
        shellHook = ''
          echo "🚀 Entering Elixir development environment"
          echo "📦 Elixir $(elixir --version)"
          echo "🔷 Erlang/OTP $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)"
        '';
      };
    }
}
```

---

## Integrating ai-rules with Nix

### Step 1: Copy Template

When initializing a project with `ai-rules`, copy appropriate Nix template:

```bash
# Universal template (recommended for most projects)
cp ai-rules/configs/nix_flake_universal.nix flake.nix

# Phoenix + Ash template (web applications)
cp ai-rules/configs/nix_flake_phoenix_ash.nix flake.nix

# Nerves template (embedded systems)
cp ai-rules/configs/nix_flake_nerves.nix flake.nix

# Or use ai-rules/scripts/init_project.sh with template selection
bash ai-rules/scripts/init_project.sh my_app phoenix-ash
```

### Step 2: Customize flake.nix

Modify the template for your project needs:

```nix
{
  description = "My Phoenix + Ash Application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    # Add your custom inputs
    my-dependency.url = "github:user/repo";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      inherit (nixpkgs) lib;
      inherit (flake-utils.lib) flake-utils;
    in
    {
      devShells.default = nixpkgs.mkShell {
        buildInputs = with pkgs; [
          # Keep Elixir, OTP, Erlang, Node.js, PostgreSQL
          pkgs.elixir_1_17
          pkgs.beamPackages.erlang_27
          pkgs.postgresql_16
          pkgs.nodejs_22
          pkgs.git

          # Add project-specific dependencies
          pkgs.credo
          pkgs.dialyxir
          pkgs.excoveralls
          pkgs.bc
          pkgs.openssl
        ];

        shellHook = ''
          # .ai_rules integration
          export AI_RULES_PATH="${toString ./.ai_rules}"

          # Local LLM paths
          export OLLAMA_HOST="http://localhost:11434"
          export LMSTUDIO_HOST="http://localhost:1234/v1"

          # MLX GPU configuration
          export MLX_TENSOR_PARALLEL="5"
          export MLX_MAX_GPUS="5"
          export MLX_VRAM_LIMIT="45000000000"
        '';
      };
    }
}
```

### Step 3: Add ai-rules Integration

Configure shell hook to integrate with `ai-rules`:

```nix
shellHook = ''
  # Symlink to ai-rules if not already linked
  if [ ! -e "ai-rules" ]; then
    echo "🔗 Linking ai-rules..."
    ln -s $AI_RULES_PATH ai-rules
  fi

  # Set environment for OpenCode
  export OPENCODE_CONFIG_PATH="${toString ./.opencode}"

  # Add mgrep to PATH (if installed)
  if command -v mgrep &> /dev/null; then
    echo "✅ mgrep available"
  else
    echo "⚠️  mgrep not found - run ai-rules/scripts/setup_opencode.sh"
  fi

  # Set up Serena MCP
  export SERENA_PROJECT_PATH="${toString ./.serena}"

  # Add scripts to PATH
  export PATH="${toString ./ai-rules/scripts}:$PATH"
'';
```

---

## GPU Acceleration (MLX)

### MLX Configuration for M2 Max

Configure MLX for Apple Silicon in your flake.nix:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    mlx.url = "github:apple/mlx";  # or your fork
  };

  outputs = { self, nixpkgs, flake-utils, mlx }:
    let
      inherit (nixpkgs) lib;
      inherit (flake-utils.lib) flake-utils;
      inherit (mlx.packages) mlx-pkgs;
    in
    {
      devShells.default = nixpkgs.mkShell {
        buildInputs = with pkgs; [
          # Standard Elixir dependencies
          pkgs.elixir_1_17
          pkgs.beamPackages.erlang_27
          pkgs.postgresql_16

          # MLX dependencies
          mlx-pkgs.mlx
          mlx-pkgs.python311
          mlx-pkgs.python311Packages.numpy
          mlx-pkgs.python311Packages.torch
        ];

        shellHook = ''
          # MLX GPU configuration for M2 Max (64GB RAM, 50GB VRAM)
          export MLX_TENSOR_PARALLEL="5"
          export MLX_MAX_GPUS="5"
          export MLX_VRAM_LIMIT="45000000000"  # 45GB

          # 4-bit quantization for faster inference
          export MLX_QUANTIZATION_BITS="4"
          export MLX_QUANTIZATION_GROUP_SIZE="128"

          # Batch sizes per mode
          export MLX_BATCH_PLAN="1"
          export MLX_BATCH_BUILD="4"
          export MLX_BATCH_REVIEW="8"

          # Temperature settings
          export MLX_TEMP_PLAN="0.7"
          export MLX_TEMP_BUILD="0.3"
          export MLX_TEMP_REVIEW="0.5"
        '';

        # Display GPU info on shell entry
        shellHook = ''
          echo "🖥  MLX GPU Configuration"
          echo "    Tensor Parallel: $MLX_TENSOR_PARALLEL"
          echo "    Max GPUs: $MLX_MAX_GPUS"
          echo "    VRAM Limit: $MLX_VRAM_LIMIT"
          echo "    Batch (Plan): $MLX_BATCH_PLAN"
          echo "    Batch (Build): $MLX_BATCH_BUILD"
          echo "    Batch (Review): $MLX_BATCH_REVIEW"
        '';
      };
    }
}
```

### MLX Model Paths

Configure MLX model paths in flake.nix:

```nix
shellHook = ''
  # MLX model directory
  export MLX_MODELS_PATH="${toString ./mlx_models}"

  # Common MLX model paths
  export MLX_LLAMA3_70B="${MLX_MODELS_PATH}/llama-3.1-70b-instruct"
  export MLX_DEEPSEEK_16B="${MLX_MODELS_PATH}/deepseek-coder-v2-16b"
  export MLX_PHI4_MINI="${MLX_MODELS_PATH}/phi-4-mini-instruct"
'';
```

---

## Local LLM Integration

### Ollama Configuration

Configure Ollama in your flake.nix:

```nix
{
  outputs = { self, nixpkgs, ... }:
    {
      devShells.default = nixpkgs.mkShell {
        buildInputs = with pkgs; [
          pkgs.elixir_1_17
          pkgs.ollama  # If available in nixpkgs
        ];

        shellHook = ''
          # Ollama configuration
          export OLLAMA_HOST="http://localhost:11434"
          export OLLAMA_MODELS="${toString ./ollama_models}"

          # Default model per mode (can be overridden)
          export OLLAMA_MODEL_PLAN="llama3.1:70b-instruct-q8_0"
          export OLLAMA_MODEL_BUILD="deepseek-coder-v2:16b-instruct"
          export OLLAMA_MODEL_REVIEW="llama3.1:70b-instruct-q8_0"

          # Ollama options
          export OLLAMA_NUM_GPU="1"  # Auto-detect
          export OLLAMA_NUM_THREAD="8"
          export OLLAMA_KEEP_ALIVE="30m"  # Keep loaded for 30 min
        '';
      };
    }
}
```

### LM Studio Configuration

Configure LM Studio in your flake.nix:

```nix
{
  outputs = { self, nixpkgs, ... }:
    {
      devShells.default = nixpkgs.mkShell {
        buildInputs = with pkgs; [
          pkgs.elixir_1_17
        ];

        shellHook = ''
          # LM Studio configuration
          export LMSTUDIO_HOST="http://localhost:1234/v1"

          # Default model per mode
          export LMSTUDIO_MODEL_PLAN="phi-4-mini-instruct"
          export LMSTUDIO_MODEL_BUILD="phi-4-mini-instruct"
          export LMSTUDIO_MODEL_REVIEW="phi-4-mini-instruct"

          # LM Studio options
          export LMSTUDIO_TEMPERATURE_PLAN="0.7"
          export LMSTUDIO_TEMPERATURE_BUILD="0.3"
          export LMSTUDIO_TEMPERATURE_REVIEW="0.5"

          # Context window
          export LMSTUDIO_MAX_TOKENS="4096"
          export LMSTUDIO_CONTEXT_WINDOW="8192"
        '';
      };
    }
}
```

---

## Workflow with Nix

### Enter Development Shell

```bash
# With direnv (recommended - automatic)
direnv reload

# Or manually
nix develop

# With specific shell
nix develop .#default
```

### Run Commands in Nix Shell

All Mix commands work normally in Nix shell:

```bash
# Enter Nix shell
nix develop

# Run Mix commands
mix deps.get
mix compile
mix test
mix format
mix credo
```

### Run OpenCode in Nix Shell

OpenCode works seamlessly with Nix shell:

```bash
# Enter Nix shell
nix develop

# Start OpenCode (it will use shell environment)
opencode --config .opencode/opencode.build.json
```

---

## Common Issues

### Issue: flake.nix Not Found

**Symptom**:
```bash
error: flake 'flake.nix' does not provide attribute 'packages.x86_64-darwin.default' for 'x86_64-darwin'
```

**Solution**:
```bash
# Check syntax
nix flake check

# Ensure flake.nix is in project root
ls -la flake.nix

# Rebuild flake cache
rm -rf .direnv/flake-profile
nix develop
```

### Issue: Dependencies Not Found

**Symptom**:
```bash
error: attribute 'elxir_1_17' missing
```

**Solution**:
```bash
# Check available package names
nix search elixir

# Use generic package name
pkgs.elixir

# Or pin specific version
pkgs.elixir.override { version = "1.17.3"; }
```

### Issue: GPU Not Available

**Symptom**:
```text
MLX error: No GPUs found
```

**Solution**:
```bash
# Check GPU availability
system_profiler SPDisplaysDataType | grep "GPU"

# Reduce GPU count in MLX configuration
export MLX_MAX_GPUS="3"  # Instead of 5

# Use CPU-only mode
export MLX_GPU_ACCELERATION="false"
```

### Issue: Local LLM Not Accessible

**Symptom**:
```bash
Error: Connection refused to Ollama/LM Studio
```

**Solution**:
```bash
# Start Ollama
ollama serve

# Start LM Studio
# Run LM Studio application
# Check it's running on expected port (usually 1234)

# Check firewall
# Ensure localhost connections are allowed
```

---

## Using Existing flake.nix

If you already have a custom flake.nix, integrate `ai-rules` by:

### Option 1: Add Inputs

Add `ai-rules` as an input to your flake.nix:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    ai-rules.url = "github:layeddie/.ai_rules";  # Your repo URL
  };

  outputs = { self, nixpkgs, flake-utils, ai-rules }:
    let
      inherit (nixpkgs) lib;
      inherit (flake-utils.lib) flake-utils;
      inherit (ai-rules) lib ai-rules-lib;
    in
    {
      devShells.default = nixpkgs.mkShell {
        buildInputs = with pkgs; [
          pkgs.elixir_1_17
          # Your existing dependencies
          # ai-rules dependencies (if available)
        ] ++ (ai-rules-lib.defaultDependencies pkgs);

        shellHook = ''
          # Your existing shell hooks
          # .ai_rules integration
        '';
      };
    }
}
```

### Option 2: Copy Configuration

Copy relevant sections from `ai-rules` template to your flake.nix:

- Build inputs for your project
- Shell hooks for local LLMs
- MLX GPU configuration
- OpenCode integration

---

## Nix + OpenCode Workflow

### Complete Workflow

```bash
# 1. Enter Nix shell
nix develop

# 2. Start plan session (Terminal 1)
opencode --config .opencode/opencode.plan.json

# 3. Start build session (Terminal 2, in same Nix shell)
opencode --config .opencode/opencode.build.json

# 4. Start review session (Terminal 3, optional)
opencode --config .opencode/opencode.review.json
```

### Advantages of Nix + OpenCode

- **Reproducible Environment**: Same dependencies everywhere
- **GPU Acceleration**: MLX configured for M2 Max
- **Local LLM Integration**: Ollama/LM Studio paths set automatically
- **Isolated Development**: No global dependencies conflicts
- **Easy Setup**: `nix develop` provides complete environment

---

## Summary

Nix integration with `.ai_rules` provides:

✅ **Reproducible Environment**: Pinned Elixir, OTP, Erlang, Node.js
✅ **GPU Acceleration**: MLX configured for M2 Max (5 GPUs, 4-bit quantization)
✅ **Local LLM Support**: Ollama, LM Studio paths configured
✅ **OpenCode Integration**: Environment variables set for tooling
✅ **.ai_rules Integration**: Scripts and configs available in PATH

**For detailed configuration**, see:
- `configs/nix_flake_universal.nix` - Universal Elixir template
- `configs/nix_flake_phoenix_ash.nix` - Phoenix + Ash template
- `configs/nix_flake_nerves.nix` - Nerves embedded systems template
- `configs/mlx_gpu_config.yml` - MLX GPU settings
- `PROJECT_INIT.md` - Overall project initialization

**For .ai_rules best practices**, see:
- `AGENTS.md` - Agent guidelines
- `../../roles/` - Role definitions
- `../../skills/` - Technical skills

---

**Happy coding with Nix and .ai_rules! 🎉**

---

## Version Flexibility

### Philosophy

ai-rules supports flexible Elixir versioning to accommodate:
- Project-specific requirements (may need older stable versions)
- Nix environment overrides (version can be specified per shell session)
- Team preferences (latest stable vs cutting edge)
- Testing scenarios (test compatibility across versions)

### Approaches

#### 1. Flakes (Default - Use Flexible Versioning)

Nix flake.nix templates use `~>` for flexible versions:

\`\`\`nix
pkgs.elixir_1_17        # Allows 1.17+ (e.g., 1.18, 1.19)
pkgs.phoenix_1_7_14      # Allows 1.7+ (e.g., 1.8, 1.9)
pkgs.beam_27              # Allows 27+ (e.g., 28, 29)
pkgs.erlang_26            # Allows 26+ (e.g., 27, 28)
\`\`\`

**Advantages**:
- Latest stable with automatic updates
- Bug fixes and security patches
- New features and deprecation warnings

**When to Override**:
\`\`\`bash
# In flake.nix, specify exact version
pkgs.elixir.override { version = "1.17.3"; }

# Or use different version range
pkgs.elixir_1_16             # Downgrade for testing
\`\`\`

#### 2. Shell Session Overrides

Nix devshell allows version specification per session:

\`\`\`bash
# Use latest stable Elixir
nix develop .#elixir_1_17

# Or use specific version
nix develop .#elixir_1_16

# Or use flexible versioning
nix develop .#elixir_1_17+

# Or use ASDF
nix develop . --impure env=Elixir ASDF_ELIXIR_VERSION=1_17_3
\`\`\`

#### 3. ASDF Integration (Preferred for Development)

Use ASDF for per-project version management:

\`\`\`bash
# Install tooling in Nix devshell
pkgs.asdf_2_7_5
pkgs.asdf_elixir_1_17_3

# Switch versions dynamically
asdf elixir global 1.17.3
asdf elixir local 1.18.0
asdf elixir local 1.19.0

# Nix devshell includes ASDF in PATH
\`\`\`

**Advantages**:
- Project-specific version control
- Team coordination
- Rollback capabilities
- Reproducible team environments

### Templates Remain Unchanged

**Keep templates with old version references** - This is intentional and correct:
- \`scripts/init_project.sh\` generates mix.exs with \`~>\`
- Template files use \`~>\` for flexibility
- Mix will resolve to latest stable or specified version
- Documented in this section that overrides are possible

### Usage Guide

#### For New Projects
\`\`\`bash
# Use default flexible versions (recommended)
bash ai-rules/scripts/init_project.sh my_app

# Override Elixir version in flake.nix
# Add to buildInputs:
pkgs.elixir_1_17_3   # Specific version
\`\`\`

#### For Existing Projects
\`\`\`bash
# Override in flake.nix
pkgs.elixir_1_17_3

# Use ASDF in Nix shell
nix develop
asdf elixir local 1.17.3

# Mix still respects MIX_ENV and deps
\`\`\`

#### Version Testing
\`\`\`bash
# Test different Elixir versions in Nix
nix develop .#elixir_1_16
mix test
nix develop .#elixir_1_17_0
mix test

# Switch back
asdf elixir local 1.17.3
\`\`\`

### Troubleshooting

#### Issue: Version Conflicts
\`\`\`bash
# Clear Nix cache
rm -rf .direnv/flake-profile
nix develop

# Rebuild
rm -rf _build deps mix.lock
mix deps.get
mix compile
\`\`\`

#### Issue: Mix Can't Find Packages
\`\`\`bash
# Mix environment
mix local.hex --force
mix archive.uninstall unused
\`\`\`

### Notes

- Old version references (\`~> 1.17\`) in templates are CORRECT and intentional
- They provide flexibility for users who need specific versions
- Nix devshell allows session-level overrides
- ASDF provides project-level version control
- Mix respects environment and can be overridden
