# usage_rules Integration Guide

This guide explains how to integrate `usage_rules` tool into ai-rules for Elixir development.

## Quick Start

### Installation
```bash
# Add to mix.exs (dev dependencies)
def deps do
  [
    {:usage_rules, "~> 0.1", only: [:dev], runtime: false}
  ]
end

# Install
mix deps.get
```

### Initial Sync
```bash
# Sync all dependencies with AGENTS.md
bash scripts/sync_usage_rules.sh

# Or use alias (add to mix.exs aliases)
defp aliases do
  [
    "usage_rules.update": [
      "usage_rules.sync AGENTS.md --all --link-to-folder deps --inline usage_rules:all"
    ]
  ]
end
```

## When to Run usage_rules Sync

### Before Plan Session
```bash
# Update rules before starting architectural work
mix usage_rules.sync AGENTS.md --all --link-to-folder deps
```

### After Dependency Updates
```bash
# When adding new packages with usage-rules.md files
mix usage_rules.sync AGENTS.md new_package_name --link-to-folder deps
```

### Before Build Session (Optional)
```bash
# Quick sync of specific package
mix usage_rules.sync AGENTS.md ash phoenix
```

## Best Practices

### Use Folder Links
- **Prefer `--link-to-folder deps`**: Saves tokens, links to source files
- **Avoid `--inline` for large rules**: Keep AGENTS.md readable
- **Combine both**: Use `--inline usage_rules:all` for Elixir standards + folder links for dependencies

### Search hexdocs
```bash
# Search all package documentation
mix usage_rules.search_docs "authentication pattern"

# Search specific packages
mix usage_rules.search_docs "validation" -p ecto -p ash

# Search only titles (fast)
mix usage_rules.search_docs "GenServer" --query-by title
```

### Check Status
```bash
# List available packages
mix usage_rules.sync --list

# Check current status
mix usage_rules.sync AGENTS.md --list
```

## OpenCode Integration

### Plan Mode
- usage_rules provides dependency rules
- LLM can reference usage-rules.md in deps/ when designing architecture
- Use `mix usage_rules.search_docs` to find patterns in dependencies

### Build Mode
- usage_rules ensures current dependency rules are available
- Use folder links to keep AGENTS.md token-efficient
- Sync before implementing features from new packages

### Review Mode
- usage_rules provides authoritative patterns from dependencies
- Cross-reference dependency usage rules when reviewing code

## Troubleshooting

### usage_rules Not Installed
```bash
# Check if installed
mix help usage_rules.sync

# Add to mix.exs
{:usage_rules, "~> 0.1", only: [:dev], runtime: false}

# Install
mix deps.get
```

### Sync Errors
```bash
# Check dependency has usage-rules.md
grep "usage_rules" deps/<package>/mix.exs

# Try sync with specific package
mix usage_rules.sync AGENTS.md <package_name>
```

## Key Resources

- **usage_rules GitHub**: https://github.com/ash-project/usage_rules
- **usage_rules Documentation**: https://hexdocs.pm/usage_rules
- **Elixir usage_rules**: Inline in mix.exs (via `--inline usage_rules:all`)
