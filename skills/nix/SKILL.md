# Nix Package Management

**Skill Type**: Technical Expertise
**Purpose**: Nix configuration for reproducible Elixir/BEAM development with GPU acceleration
**Philosophy**: Nix-first development environment, flexible versioning, deterministic builds

---

## Core Principles

### Reproducibility First
- Same dependencies across all developers
- Pinned package versions
- Isolated build environments
- No global dependencies required

### Flexible Versioning
- **Flakes (default)**: Use `~>` for flexible versioning
- **NixOS**: Version channels for system packages
- **DevShell overrides**: Session-level version specification
- **ASDF integration**: Project-specific version control

### GPU Acceleration
- MLX optimization for Apple Silicon M2 Max
- Tensor parallelism for maximum throughput
- Quantization for memory efficiency
- Flexible batch sizes per development mode

### Integration with ai-rules
- OpenCode integration via environment variables
- Serena MCP project path configuration
- Local LLM path management
- Git workflow support

---

## Nix Fundamentals

### What is Nix?

Nix is a package manager and build system that provides:
- **Reproducible Builds**: Same environment everywhere
- **Declarative**: Declare dependencies in flake.nix
- **Isolated**: No global state pollution
- **Multi-user**: Each user has their own nix store

### Flakes (Modern Nix)

Flakes are the modern Nix approach with:
- `flake.nix`: Reproducible project configuration
- **Pinned Inputs**: Exact versions of dependencies
- **Deterministic**: Build outputs from pure functions
- **Per-project**: Each project has its own flake

### DevShell

Isolated shell environments with:
- Project-specific dependencies
- Shell hooks for environment setup
- Easy access to build tools
- Automatic environment variable configuration

---

## Elixir/OTP in Nix

### Dependency Management

```nix
{
  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs;
    in
    {
      devShells.default = nixpkgs.mkShell {
        buildInputs = with pkgs; [
          # Elixir (flexible versioning with ~>)
          pkgs.elixir_1_17        # Latest stable
          
          # OTP (latest stable)
          pkgs.beamPackages.erlang_27
          
          # Database
          pkgs.postgresql_16
          
          # Node.js for Phoenix assets
          pkgs.nodejs_22
          
          # Development tools
          pkgs.git
          pkgs.credo
          pkgs.dialyxir
          pkgs.excoveralls
          pkgs.bc
          pkgs.openssl
        ];
      };
    }
}
```

### Version Pinning Strategies

#### 1. Flexible Versioning (Recommended)

```nix
pkgs.elixir_1_17         # Allows 1.17, 1.18, 1.19...
pkgs.phoenix_1_7_14       # Allows 1.7, 1.8, 1.9...
pkgs.beam_27             # Allows 27, 28, 29...
pkgs.erlang_26            # Allows 26, 27, 28...
```

**Advantages**:
- Latest stable with automatic updates
- Bug fixes and security patches
- Testing across versions

**When to Use**:
- New projects starting development
- Projects without specific version requirements
- Teams using latest Elixir/Ash

#### 2. Specific Version Pinning

```nix
pkgs.elixir_1_17_3       # Exact version
pkgs.beamPackages.erlang_27_3_2  # Specific OTP
pkgs.phoenix_1_7_14_3    # Specific Phoenix
```

**Advantages**:
- Reproducible builds
- Version guarantees
- Production deployments

**When to Use**:
- Production releases
- Projects with strict version requirements
- CI/CD pipelines

#### 3. ASDF Integration (Project-Level)

Use ASDF for per-project version control:

```nix
{
  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs;
    in
    {
      devShells.default = nixpkgs.mkShell {
        buildInputs = with pkgs; [
          pkgs.elixir
          pkgs.beamPackages.erlang
          pkgs.asdf_2_7_5
          pkgs.asdf_elixir_1_17_3
        ];

        shellHook = ''
          # ASDF in PATH
          export PATH="$PWD/.asdf-shims:$PATH"
          
          # Set project Elixir version
          asdf elixir local 1.17.3
        '';
      };
    }
}
```

**Advantages**:
- Fine-grained version control
- Team coordination
- Easy rollback
- Reproducible team environments

**When to Use**:
- Teams with version coordination needs
- Projects with specific dependency requirements
- Development vs production environment parity

---

## MLX GPU Acceleration

### Apple Silicon M2 Max Configuration

For M2 Max with 64GB RAM and 50GB VRAM:

```yaml
# MLX Environment Variables
tensor_parallel: 5
max_gpus: 5
vram_limit: 45000000000  # 45GB

# Quantization
quantization_bits: 4
quantization_group_size: 128

# Batch sizes per mode
batch_plan: 1        # Architecture planning
batch_build: 4        # Code generation
batch_review: 8        # Code review

# Temperature settings
temp_plan: 0.7
temp_build: 0.3
temp_review: 0.5
```

### GPU Configuration in flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    mlx.url = "github:apple/mlx";
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
          pkgs.elixir_1_17
          pkgs.beamPackages.erlang_27
          pkgs.postgresql_16
          pkgs.nodejs_22
          
          # MLX dependencies
          mlx-pkgs.mlx
          mlx-pkgs.python311
          mlx-pkgs.python311Packages.numpy
          mlx-pkgs.python311Packages.torch
        ];

        shellHook = ''
          # MLX GPU Configuration
          export MLX_TENSOR_PARALLEL="5"
          export MLX_MAX_GPUS="5"
          export MLX_VRAM_LIMIT="45000000000"
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
      };
    }
}
```

---

## DevShell Workflow

### Entering DevShell

```bash
# With direnv (recommended)
direnv reload

# Or manually
nix develop

# With specific package overrides
nix develop .#elixir=1_16
```

### Version Override Examples

```bash
# Override to test older version
nix develop .#elixir=1_16
mix test

# Switch back to stable
nix develop .#elixir=1_17_3
```

### ASDF Version Management

```bash
# Switch project Elixir version
asdf elixir local 1.17.3

# List installed versions
asdf list elixir

# Test new version temporarily
asdf shell elixir 1.18.0

# Revert to project version
asdf elixir local 1.17.3
```

---

## Shell Hooks

### ai-rules Integration

```nix
shellHook = ''
  # Link to ai-rules if not already linked
  if [ ! -e "ai-rules" ]; then
    echo "🔗 Linking ai-rules..."
    ln -s $AI_RULES_PATH ai-rules
  fi

  # Set environment for OpenCode
  export OPENCODE_CONFIG_PATH="${toString ./.opencode}"

  # Set up Serena MCP
  export SERENA_PROJECT_PATH="${toString ./.serena}"

  # Add scripts to PATH
  export PATH="${toString ./ai-rules/scripts}:$PATH"
'';
```

### Local LLM Integration

```nix
shellHook = ''
  # Ollama configuration
  export OLLAMA_HOST="http://localhost:11434"
  export OLLAMA_MODELS="${toString ./ollama_models}"

  # LM Studio configuration
  export LMSTUDIO_HOST="http://localhost:1234/v1"
'';
```

### GPU Resource Management

```nix
shellHook = ''
  # Monitor GPU usage
  echo "🖥  MLX GPU Configuration"
  echo "    Tensor Parallel: $MLX_TENSOR_PARALLEL"
  echo "    Max GPUs: $MLX_MAX_GPUS"
  echo "    VRAM Limit: $MLX_VRAM_LIMIT"
  
  # Display model paths
  echo "    Plan Model: $MLX_LLAMA3_70B"
  echo "    Build Model: $MLX_DEEPSEEK_16B"
'';
```

---

## Version Testing Strategies

### Testing Elixir Versions

```bash
# Test different Elixir versions in Nix
nix develop .#elixir_1_16
mix test

nix develop .#elixir_1_17_0
mix test

# Switch back to stable
asdf elixir local 1.17.3
```

### Testing Ash Compatibility

```bash
# Test Ash package compatibility
mix deps.get
mix test

# Use Nix devshell with different Elixir
nix develop .#elixir_1_16
mix deps.get
mix test
```

### Testing Dependency Conflicts

```bash
# Clear Mix cache
rm -rf _build deps mix.lock
mix deps.get

# Rebuild dependencies
mix deps.get
mix compile
```

---

## Cross-Platform Development

### macOS (Primary Platform)

```bash
# Native Nix
nix develop

# With direnv
nix develop

# With ASDF
asdf install elixir latest
asdf global elixir latest
```

### Linux

```bash
# Native Nix
nix-channel --update
nixos-rebuild

# With NixOS
nix-channel --update
```

### NixOS

```bash
# NixOS package management
nix-channel --update
nixos-rebuild switch
```

---

## Integration with Other Tools

### Igniter Integration

**Critical**: Nix environment must match what Igniter expects

When using Igniter with Ash/Phoenix:

```bash
# 1. Nix Specialist provides guidance on version selection
nix-specialist:
  "We need Ash 3.4+ for this project"
  "Nix 1.17+ supports this"

# 2. Architect considers Nix in design phase
architect:
  "Use Igniter to explore Ash 3.4+"
  "Nix specialist confirmed 1.17+ compatibility"

# 3. Orchestrator sets up Nix devshell with correct version
orchestrator:
  "Setting up Nix devshell"
  "Use Ash 3.4+ from Nix"

# 4. Test Ash compatibility
mix test
```

### OpenCode Integration

```nix
shellHook = ''
  export OPENCODE_CONFIG_PATH="${toString ./.opencode}"
  export MLX_TENSOR_PARALLEL="5"
  export MLX_MAX_GPUS="5"
'';
```

### Serena MCP Integration

```nix
shellHook = ''
  export SERENA_PROJECT_PATH="${toString ./.serena}"
'';
```

---

## Common Issues

### Issue: Nix Cache Corrupted

**Symptom**:
```
error: hash mismatch in fixed-output derivation
```

**Solution**:
```bash
# Clear Nix cache
rm -rf ~/.cache/nix
rm -rf .direnv/flake-profile

# Rebuild
nix develop
```

### Issue: Package Not Found

**Symptom**:
```
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
```
MLX error: No GPUs found
```

**Solution**:
```bash
# Check GPU availability
system_profiler SPDisplaysDataType | grep "GPU"

# Reduce GPU count in MLX configuration
export MLX_MAX_GPUS="3"

# Use CPU-only mode
export MLX_GPU_ACCELERATION="false"
```

### Issue: Mix Can't Find Dependencies

**Symptom**:
```
** (Mix) Could not find dependency
```

**Solution**:
```bash
# Mix environment
mix local.hex --force
mix archive.uninstall unused

# Clear cache
rm -rf _build deps mix.lock
mix deps.get
```

---

## When to Use This Skill

Invoke Nix specialist when:
- Setting up new Elixir projects with Nix
- Configuring reproducible development environments
- Optimizing MLX GPU performance for AI workloads
- Managing Elixir/OTP version compatibility
- Setting up CI/CD with Nix
- Troubleshooting Nix issues
- Deciding on Nix vs ASDF vs Docker for development

---

## Key Resources

- [Nix Manual](https://nixos.org/manual/en/stable/)
- [Nixpkgs Search](https://search.nixos.org/packages)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [MLX Documentation](https://github.com/apple/mlx)
- [Nix Pills](https://nixos.org/guides/nix-pills/)

---

**Follow this skill to ensure reproducible Nix environments that integrate seamlessly with ai-rules workflow and provide GPU acceleration for AI/ML workloads.**
