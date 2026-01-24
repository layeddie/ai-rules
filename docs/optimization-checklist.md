# AI-Rules Token Optimization Checklist

**Created**: 2026-01-25  
**Branch**: `feature/optimize-token-efficiency`  
**Tracking**: Progress of token efficiency implementation

---

## ✅ Prerequisites (Complete)

- [x] Review completed by Beam-Review (2026-01-24)
- [x] Local models tested (Ollama + LM Studio)
- [x] OpenCode configuration updated
- [x] Implementation plan created (`docs/implementation_plan.md`)
- [x] M2 Max Metal/MLX confirmed

---

## 🚀 Phase 1: Branch Setup

### Step 1.1: Create Feature Branch
```bash
git checkout main
git pull origin main
git checkout -b feature/optimize-token-efficiency
```
- [ ] Create `feature/optimize-token-efficiency` branch from main
- [ ] Verify branch created successfully
- [ ] Sync with origin/main

---

## 📋 Phase 2: Mode-Specific MCP Configurations

### Step 2.1: Plan Mode Configuration
**File**: `.opencode/opencode.plan.json`
**Goal**: Disable redundant tools, keep essentials only

**Plan mode tools**:
- ✅ Serena (read-only) - Semantic search
- ✅ mgrep (via bash) - Codebase discovery
- ✅ grep - Exact pattern matching
- ✅ websearch - External docs
- ❌ jido_ai - Not needed for planning
- ❌ swarm_ex - Not needed for planning
- ❌ codicil - Use mgrep instead
- ❌ probe - Use mgrep instead

- [ ] Create `.opencode/opencode.plan.json`
- [ ] Test plan mode config
- [ ] Verify only essential tools active
- [ ] Document tool usage patterns

### Step 2.2: Build Mode Configuration
**File**: `.opencode/opencode.build.json`
**Goal**: Full coding capability with backup

**Build mode tools**:
- ✅ Serena (full) - Primary semantic search + editing
- ✅ codicil - Elixir-native backup
- ✅ bash - Run mix commands, tests
- ✅ write/edit - File operations
- ✅ grep - Fast searches
- ❌ jido_ai - Keep for complex tasks only
- ❌ swarm_ex - Lightweight enough
- ❌ probe - Use mgrep instead

- [ ] Create `.opencode/opencode.build.json`
- [ ] Test build mode config
- [ ] Verify Serena + codicil work together
- [ ] Test file operations work

### Step 2.3: Review Mode Configuration
**File**: `.opencode/opencode.review.json`
**Goal**: Analysis-only with cross-reference

**Review mode tools**:
- ✅ Serena (read-only) - Context understanding
- ✅ mgrep - Cross-reference patterns
- ✅ grep - Pattern verification
- ✅ bash - Quality checks (credo, dialyzer)
- ❌ write/edit - Analysis only
- ❌ jido_ai - Not needed for review
- ❌ swarm_ex - Not needed for review
- ❌ codicil - Use Serena instead
- ❌ probe - Use mgrep instead

- [ ] Create `.opencode/opencode.review.json`
- [ ] Test review mode config
- [ ] Verify analysis-only tools work
- [ ] Test quality check commands

---

## 🚫 Phase 3: Filtering and Ignore Files

### Step 3.1: Create mgrepignore
**File**: `.mgrepignore`
**Purpose**: Prevent indexing of gitignored/large files

**Ignored paths**:
- [ ] Add `sessions/` (472KB+ of old sessions)
- [ ] Add `_build/` (compile artifacts)
- [ ] Add `deps/` (dependencies)
- [ ] Add `.elixir_ls/` (language server)
- [ ] Add `node_modules/` (Node deps)
- [ ] Add `*.beam` (compiled files)
- [ ] Add `*.ez` (releases)
- [ ] Add `erl_crash.dump` (crash dumps)
- [ ] Add file size limit (1MB) to config

- [ ] Test mgrep respects ignore file
- [ ] Verify large files skipped
- [ ] Document ignore patterns

### Step 3.2: Configure Serena Ignore
**File**: `.serena/.ignore` (if supported)
**Purpose**: Prevent Serena from indexing irrelevant files

- [ ] Check if Serena supports ignore file
- [ ] Create ignore configuration
- [ ] Test with sample search
- [ ] Document Serena behavior

---

## 📝 Phase 4: Condense Agent Files

### Step 4.1: Condense beam-plan.md
**Current**: 66 lines → **Target**: ≤50 lines
**Approach**: Links to detailed docs, conditional reading

**Content structure**:
```markdown
---
description: BEAM Architecture Planning
mode: primary
temperature: 0.1
tools:
  mgrep: true  # via bash
  grep: true
  websearch: true
permission:
  write: deny
---

You are a BEAM/Elixir Architect in **PLAN MODE**.

## Quick Reference
- Always read: `docs/plan-workflow.md` (10 lines)
- OTP supervision: See `patterns/otp_supervisor.md` (link)
- Domain boundaries: See `patterns/ash_resources.md` (link)
- Full guidelines: `roles/architect.md` (read only if needed)

## Tools
- **mgrep** (via bash): Semantic search for patterns
- **grep**: Exact symbol/module name search
- **websearch**: External best practices

## Output
- Architecture plan in `project_requirements.md`
- File structure (lib/, test/, config/)
- Supervision tree design

## Boundaries
- Read-only mode (no file edits)
- Use `mgrep -m 20` to limit results
- Ask before major architectural changes
```

- [ ] Create condensed `beam-plan.md` (≤50 lines)
- [ ] Keep core responsibilities
- [ ] Replace examples with links
- [ ] Add conditional reading instructions
- [ ] Test agent understands condensed format

### Step 4.2: Condense beam-build.md
**Current**: 74 lines → **Target**: ≤50 lines
**Focus**: Implementation coordination, TDD workflow

- [ ] Create condensed `beam-build.md` (≤50 lines)
- [ ] Keep essential workflow steps
- [ ] Replace detailed examples with links
- [ ] Add Serena + codicil usage patterns
- [ ] Test with simple implementation task

### Step 4.3: Condense beam-review.md
**Current**: 81 lines → **Target**: ≤50 lines
**Focus**: Quality analysis, OTP verification

- [ ] Create condensed `beam-review.md` (≤50 lines)
- [ ] Keep review checklist items
- [ ] Replace full examples with links
- [ ] Add cross-reference guidance
- [ ] Test with sample code review

---

## 🗂️ Phase 5: Content Consolidation

### Step 5.1: Map Content Sources
**Goal**: Single source of truth, eliminate duplication

| Topic | Current Locations | Target Location |
|--------|-------------------|-----------------|
| GenServer patterns | roles/architect.md, patterns/genserver.md, skills/otp-patterns/ | patterns/genserver.md |
| Supervisor strategies | roles/architect.md, patterns/otp_supervisor.md, skills/otp-patterns/ | patterns/otp_supervisor.md |
| Error handling | patterns/error_handling.md, roles/qa.md, skills/resilience-patterns/ | patterns/error_handling.md |
| Testing TDD | roles/orchestrator.md, AGENTS.md, TESTING_CHECKLIST.md | TESTING_CHECKLIST.md |
| OTP principles | roles/architect.md, skills/otp-patterns/ | skills/otp-patterns/ |

- [ ] Document content mapping decisions
- [ ] Create cross-reference links
- [ ] Remove redundant examples from roles/
- [ ] Keep patterns/ as single source for code examples
- [ ] Update skills/ for tool-specific guidance

### Step 5.2: Update Cross-References
**Approach**: Replace duplicates with links

- [ ] Update `roles/architect.md` with links to patterns/
- [ ] Update `roles/orchestrator.md` with links to skills/
- [ ] Update `roles/reviewer.md` with links to patterns/
- [ ] Ensure all links work correctly
- [ ] Document content hierarchy

---

## 📚 Phase 6: Documentation and Guides

### Step 6.1: Create Token Efficiency Guide
**File**: `docs/token-efficiency-guide.md`
**Content**: Best practices, metrics, budgets

**Sections**:
1. Token budgets per phase (plan/build/review)
2. Tool selection heuristics (when to use what)
3. mgrep vs Serena vs codicil patterns
4. Common token-saving techniques
5. Tracking templates

- [ ] Create `docs/token-efficiency-guide.md`
- [ ] Include token budget tables
- [ ] Add tool selection flowchart
- [ ] Document mgrep usage patterns
- [ ] Add tracking formulas

### Step 6.2: Add Conditional Reading
**Files to update**: All agent files, AGENTS.md
**Purpose**: Only read relevant sections per task

**Examples**:
- "Read sections 1-3: Always (core principles)"
- "Read section 4: Only if designing supervision trees"
- "Skip section 5: Hardware-specific content"

- [ ] Update all agent files with conditional reading
- [ ] Update AGENTS.md guidelines
- [ ] Add task-based reading examples
- [ ] Test conditional reading works

---

## 📊 Phase 7: Testing and Validation

### Step 7.1: Mode Testing
**Goal**: Verify each mode works with new configuration

**Test scenarios**:
- Plan: Architecture design task
- Build: Feature implementation task
- Review: Code review task

- [ ] Test plan mode with condensed files
- [ ] Test build mode with Serena + codicil
- [ ] Test review mode with analysis-only tools
- [ ] Measure token usage for each test
- [ ] Compare with baseline metrics

### Step 7.2: Integration Testing
**Full workflow**: Plan → Build → Review

- [ ] Run complete workflow on sample project
- [ ] Track total token usage
- [ ] Verify 66% reduction target met
- [ ] Document any issues found
- [ ] Create troubleshooting guide

---

## 📈 Phase 8: Metrics and Success

### Success Criteria
- [ ] All agent files ≤80 lines (target: 50-80 lines)
- [ ] Zero content duplication across roles/skills/patterns
- [ ] All MCP configs mode-specific (no redundant tools)
- [ ] `.mgrepignore` file active and working
- [ ] Token reduction ≥60% (target: 66%)
- [ ] Full documentation updated

### Performance Metrics
| Metric | Baseline | Target | Actual |
|--------|----------|--------|--------|
| Tokens/plan | 50K | 20K | TBD |
| Tokens/build | 120K | 40K | TBD |
| Tokens/review | 80K | 25K | TBD |
| Total/project | 250K | 85K | TBD |
| Cost/project | $0.75 | $0.26 | TBD |

- [ ] Measure baseline token usage
- [ ] Track implementation token usage
- [ ] Calculate final reduction percentage
- [ ] Document cost savings
- [ ] Create performance report

---

## 🚀 Phase 9: Git Workflow

### Step 9.1: Commit Changes
Following `git_rules.md` conventions

- [ ] Stage all changes: `git add .`
- [ ] Conventional commit: `git commit -m "feat: implement token optimization plan"`
- [ ] Push branch: `git push -u origin feature/optimize-token-efficiency`
- [ ] Create PR: `gh pr create --title "Implement token optimization"`

### Step 9.2: Code Review
- [ ] Request review from maintainer
- [ ] Address any feedback
- [ ] Ensure all tests pass
- [ ] Verify quality checks (credo, dialyzer)
- [ ] Merge with squash: `gh pr merge --squash`

### Step 9.3: Cleanup
- [ ] Switch to main: `git checkout main`
- [ ] Pull latest: `git pull origin main`
- [ ] Delete branch: `git branch -d feature/optimize-token-efficiency`
- [ ] Clean up any temporary files

---

## 🎯 Quick Start Summary

**Ready to begin**:
1. All prerequisites completed ✅
2. Implementation plan ready ✅
3. Checklist created ✅
4. Git workflow defined ✅

**Next action**: Start Phase 1 (Branch Setup)

---

**Progress Tracking**: [0/68] tasks complete (0%)  
**Estimated effort**: 4-6 hours  
**Priority**: High → Medium → Low