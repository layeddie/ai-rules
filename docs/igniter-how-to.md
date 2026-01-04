# Using Igniter with Elixir/Ash Projects

**Purpose**: Guide for using Ash Igniter tool with ai-rules projects

---

## What is Igniter?

Ash Igniter is an interactive tool that helps you learn Ash Framework through guided exploration and exercises.

## Prerequisites

```bash
# Install Igniter
npm install -g ash_igniter

# Or use npx
npx ash_igniter
```

## Quick Start

```bash
# Navigate to your ai-rules project
cd ~/projects/2026/your-project

# Start Igniter
ash_igniter

# Igniter will detect Ash resources
# Follow interactive prompts to learn patterns
```

## Integration with ai-rules

### When to Use Igniter

1. **Learning Phase**: When starting new project
   - Use Igniter to explore Ash Framework
   - Follow ai-rules for architecture setup
   - Apply patterns to resource design

2. **Debugging Phase**: When troubleshooting
   - Use Igniter to identify issues
   - Compare your implementation against Ash best practices
   - Get interactive feedback on solutions

3. **Pattern Discovery**: When designing complex features
   - Use Igniter to find proven patterns
   - Learn resource composition techniques
   - Understand query optimization strategies

## Best Practices

- Start with ai-rules documentation (README.md, AGENTS.md, roles/)
- Use Igniter to supplement, not replace, ai-rules
- Follow TDD workflow even when learning with Igniter
- Commit changes learned from Igniter experiments
- Share Igniter discoveries with team

## Common Workflows

### Learning New Ash Patterns
```bash
# Start Igniter
ash_igniter

# Choose learning path
- Resources and Actions
- Queries and Calculations
- Policies and Authorizations
- API Integrations

# Follow interactive prompts
# Practice with example code
# Apply to your project
```

### Debugging with Igniter
```bash
# In project directory
cd your-project

# Start Igniter in debug mode
ash_igniter --debug

# It will analyze your Ash setup
# Provide specific guidance
# Help identify performance issues
```

## Integration with Nix

If using Nix devshell:

```bash
# Enter devshell
nix develop

# Install Igniter in Nix environment
npm install -g ash_igniter

# Run Igniter
ash_igniter

# All packages available in Nix environment
```

## Integration with Nix Specialist

**Nix specialist** provides:
- Guidance on version selection for Igniter compatibility
- Multiple environment configurations (stable vs testing)
- Version testing strategies before full implementation

**Workflow**:

```bash
# 1. Nix Specialist (Planning)
nix-specialist:
  "We need Ash 3.4+ for this project"
  "Nix 1.17+ supports this"

# 2. Architect (Design with Igniter guidance)
architect:
  "Use Igniter to explore Ash 3.4+"
  "Nix specialist confirmed 1.17+ compatibility"

# 3. Orchestrator (Implement)
orchestrator:
  "Setting up Nix devshell"
  "Use Ash 3.4+ from Nix"

# 4. Reviewer (Verify)
reviewer:
  "Check Ash package compatibility"
  "Verify Nix environment"
  "Document version decision"
```

## Best Practices

- Follow ai-rules Architecture recommendations
- Use TDD - write tests first, then implement
- Document Ash resource decisions
- Use Nix specialist for version management
- Test Ash compatibility before full implementation
- Commit changes learned from Igniter experiments

## Common Issues

### Issue: Igniter Can't Find Ash Resources

**Solution**:
```bash
# Ensure Ash resources are defined
mix ash.setup

# Use Igniter in debug mode
ash_igniter --debug
```

### Issue: Version Conflicts

**Solution**:
```bash
# Consult Nix specialist
# Use Nix devshell with specific Elixir version
nix develop .#elixir=1_17_3

# Test with different versions
ash_igniter

# Switch back
asdf elixir local 1.17.3
```

## Key Resources

- Ash Igniter Documentation: https://github.com/ash-project/igniter
- Ash Official Docs: https://hexdocs.pm/ash
- ai-rules Ash Guidance: `skills/api-design/SKILL.md`
- Nix Specialist: `roles/nix-specialist.md`

## Notes

- Igniter is best for learning Ash Framework interactively
- For production code, follow ai-rules patterns and documentation
- Use Igniter to accelerate learning, not to skip best practices
- Nix specialist can help with version compatibility
- Follow TDD workflow even when learning with Igniter

---

**Follow this guide to integrate Igniter seamlessly with ai-rules workflow for Ash Framework learning.**
