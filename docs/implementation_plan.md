# AI-Rules Token Optimization Implementation Plan

**Created**: 2026-01-25  
**Status**: 📋 Ready to Implement  
**Objective**: Reduce token consumption by 66% (from 250K to 85K tokens per project)

---

## Executive Summary

Based on the comprehensive review from Beam-Review, this plan addresses token efficiency issues through:
1. **Mode-specific MCP configurations** (disable redundant tools)
2. **Condensed agent files** (50-80 lines max with links)
3. **Content consolidation** (single source of truth)
4. **Context filtering guidance** (conditional reading)

### Expected Savings
- **Before**: 250K tokens per project ($0.75)
- **After**: 85K tokens per project ($0.26)
- **Savings**: 66% reduction, $0.49 per project

---

## Key Decisions from Review

### MCP Server Configuration (Revised)

After reviewing `NEW_TOOLS_GUIDE.md`, the 5 tools were intentionally selected for token efficiency:
- **anubis-mcp**: Elixir MCP SDK for custom servers
- **jido_ai**: Agent orchestration with context management
- **swarm_ex**: Lightweight agent coordination
- **codicil**: Elixir-native semantic search (compiler-level)
- **probe**: AST-aware search backup

**Strategy**: Enable per mode, not disable globally.

### Local Model Setup

✅ **Ollama configured**: Port 11434, gpt-oss-20b (MLX compatible)
✅ **M2 Max optimized**: Metal 4 + MLX for 20B models
✅ **LM Studio available**: Port 5000 (backup option)
✅ **BigPickle ready**: Cloud model for token optimization work

---

## Implementation Tasks

### High Priority (Do First)

#### 1. Create Mode-Specific MCP Configurations
**Files to create**:
- `.opencode/opencode.plan.json`
- `.opencode/opencode.build.json`
- `.opencode/opencode.review.json`

**Strategy**:
- **Plan mode**: Serena (read-only), mgrep, grep. Disable: jido_ai, swarm_ex, codicil, probe
- **Build mode**: Serena (full), codicil (backup). Disable: probe
- **Review mode**: Serena (read-only), mgrep (cross-reference). Disable: jido_ai, swarm_ex, probe, codicil

#### 2. Create `.mgrepignore` File
**Purpose**: Prevent indexing of gitignored files (sessions, build artifacts)
**Content**:
```
sessions/
_build/
deps/
.elixir_ls/
node_modules/
*.beam
*.ez
erl_crash.dump
```

#### 3. Condense Agent Files
**Target**: 50-80 lines max per agent
**Approach**:
- Keep core responsibilities and tool usage
- Replace full examples with links to docs
- Add quick reference tables
- Use conditional reading instructions

**Files to update**:
- `.opencode/agents/beam-plan.md`
- `.opencode/agents/beam-build.md`
- `.opencode/agents/beam-review.md`

#### 4. Consolidate Duplicated Content
**Action**: Create single source of truth mapping
- `patterns/` → Code examples and implementation patterns
- `roles/` → High-level responsibilities and workflows
- `skills/` → Technical expertise and tool usage
- Cross-reference with section links instead of duplication

### Medium Priority (Do Soon)

#### 5. Add Conditional Reading Guidance
**Files to update**:
- All agent files (beam-*.md)
- AGENTS.md guidelines section

**Example**:
```
When planning OTP supervision trees:
  - Read: patterns/otp_supervisor.md (lines 1-200)
  - Skip: Nerves patterns, hardware-specific content
```

#### 6. Create Token Efficiency Guide
**File**: `docs/token-efficiency-guide.md`
**Content**:
- Expected tokens per phase (plan: 20K, build: 40K, review: 25K)
- Tool selection heuristics
- mgrep vs Serena vs codicil usage patterns
- Budget tracking templates

#### 7. Split Large Skill Files
**Target files**:
- `skills/elixir-architect/SKILL.md` (1,017 lines → split)
- `skills/nerves-patterns/SKILL.md` (899 lines → split)

**New structure**:
- `elixir-architect-supervision.md`
- `elixir-architect-distributed.md`
- `elixir-architect-performance.md`

### Low Priority (Nice to Have)

#### 8. Consolidate beamai.md
**Purpose**: Remove redundancy with beam-*.md files
**Action**: Convert to quick reference template

#### 9. Add Session Token Budget
**Feature**: Track and limit per-session usage
**Implementation**: Add to opencode configs with warnings

#### 10. Create Token-Efficient Examples
**Approach**: Replace full code with snippets + links
**Location**: Update all pattern files with concise examples

---

## Git Workflow

### Branch Creation
Following `git_rules.md`:

```bash
# 1. Update and create branch
git checkout main
git pull origin main
git checkout -b feature/optimize-token-efficiency

# 2. Implement changes
# (All tasks above)

# 3. Commit and PR
git add .
git commit -m "feat: implement token optimization plan"
git push -u origin feature/optimize-token-efficiency
gh pr create --title "Implement token optimization" --body "Reduces token usage by 66%"
gh pr merge --squash
```

---

## Success Metrics

### Token Usage Targets
| Phase | Current | Target | Reduction |
|--------|---------|--------|------------|
| Plan | 50K | 20K | 60% |
| Build | 120K | 40K | 67% |
| Review | 80K | 25K | 69% |
| **Total** | **250K** | **85K** | **66%** |

### Quality Metrics
- All agent files ≤ 80 lines
- Zero content duplication across roles/skills/patterns
- All MCP configs mode-specific
- mgrep ignore file active
- Token budget guide available

---

## Testing Strategy

### Before Merge
1. **Test each mode**:
   ```bash
   opencode --config .opencode/opencode.plan.json
   opencode --config .opencode/opencode.build.json
   opencode --config .opencode/opencode.review.json
   ```

2. **Verify tool usage**:
   - Plan mode: Only mgrep + grep used
   - Build mode: Serena primary, codicil backup
   - Review mode: Cross-reference only

3. **Token counting**:
   - Track usage per session
   - Verify targets met
   - Document actual savings

### After Merge
1. Update documentation with real usage data
2. Create performance comparison report
3. Share optimization results

---

## Rollback Plan

If issues arise:
1. **Revert MCP changes**: Keep original opencode_mcp.json
2. **Restore agent files**: Git revert to beam-*.md originals
3. **Fallback config**: Use working Ollama + BigPickle setup

---

## Next Actions

1. **Create branch**: `feature/optimize-token-efficiency`
2. **Implement High Priority** tasks 1-4
3. **Test each mode** with local tracking
4. **Document results** and metrics
5. **Submit PR** for review

---

**End of Implementation Plan**