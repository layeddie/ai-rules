# Content Mapping Analysis

**Created**: 2026-01-25
**Purpose**: Identify duplicated content across roles/skills/patterns for consolidation
**Goal**: Single source of truth, eliminate redundancy

---

## Current Content Overlap Analysis

### OTP Patterns
**Duplication Found**: GenServer patterns exist in 3+ locations

| Topic | Current Locations | Target Location | Rationale |
|-------|-------------------|-----------------|------------|
| GenServer patterns | roles/architect.md, patterns/genserver.md, skills/otp-patterns/ | **patterns/genserver.md** (single source) | Code examples and implementation patterns |

### Supervisor Strategies  
**Duplication Found**: Supervisor strategies duplicated across roles/skills

| Topic | Current Locations | Target Location | Rationale |
|-------|-------------------|-----------------|------------|
| Supervisor trees | roles/architect.md, patterns/otp_supervisor.md, skills/otp-patterns/ | **patterns/otp_supervisor.md** (single source) | Implementation strategies |

### Error Handling
**Duplication Found**: Error handling patterns scattered across files

| Topic | Current Locations | Target Location | Rationale |
|-------|-------------------|-----------------|------------|
| Error handling | patterns/error_handling.md, roles/qa.md, skills/resilience-patterns/ | **patterns/error_handling.md** (single source) | Comprehensive patterns |

### TDD Workflow
**Duplication Found**: TDD guidance scattered across multiple files

| Topic | Current Locations | Target Location | Rationale |
|-------|-------------------|-----------------|------------|
| TDD workflow | roles/orchestrator.md, AGENTS.md, TESTING_CHECKLIST.md | **TESTING_CHECKLIST.md** (single source) | Complete testing guide |

### OTP Principles
**Duplication Found**: Core principles repeated across roles/skills

| Topic | Current Locations | Target Location | Rationale |
|-------|-------------------|-----------------|------------|
| OTP principles | roles/architect.md, skills/otp-patterns/ | **skills/otp-patterns/** (multiple files) | Technical expertise |

---

## Consolidation Strategy

### Single Source of Truth Mapping

| Content Type | Primary Location | Secondary Locations | Action Required |
|-------------|-----------------|--------------------|-----------------|
| **Code Examples** | `patterns/` | Remove from roles/ and skills/ | Keep examples only in patterns/ |
| **High-Level Guidance** | `roles/` | Keep responsibilities and workflows | Remove detailed code examples |
| **Technical Expertise** | `skills/` | Keep tool-specific guidance | Consolidate overlapping OTP content |
| **Complete Guides** | `docs/` | Keep comprehensive guides | Reference from roles/skills |

### Cross-Reference Strategy

1. **Replace duplicates with links**:
   - roles/architect.md: "See patterns/otp_supervisor.md#strategies"
   - roles/orchestrator.md: "See patterns/tdd-workflow.md#red-green-refactor"
   - roles/reviewer.md: "See patterns/error_handling.md#best-practices"

2. **Keep examples only in patterns/**:
   - GenServer, Supervisor, Error handling implementations
   - Code snippets and pattern libraries

3. **Maintain hierarchy**:
   - roles/ → High-level responsibilities
   - skills/ → Technical expertise and tool usage
   - patterns/ → Code examples and implementations
   - docs/ → Comprehensive guides and workflows

---

## Implementation Tasks

### Task 2.1: Remove Redundant Examples from Roles
**Files to update**:
- `roles/architect.md` - Remove GenServer, supervisor examples
- `roles/orchestrator.md` - Remove TDD workflow details
- `roles/reviewer.md` - Remove code example snippets

### Task 2.2: Add Cross-Reference Links
**Updates required**:
- Add section links in all role files
- Reference specific sections in patterns/
- Use format: "See patterns/[file]#[section]"

### Task 2.3: Consolidate OTP Content in Skills
**Action**: Merge overlapping OTP content
- Remove duplicate patterns between skills/otp-patterns/* files
- Keep single comprehensive guide per topic

### Task 2.4: Update Documentation References
**Files to update**:
- AGENTS.md - Reference docs/ for workflows instead of detailed roles
- roles/ - Reference docs/ patterns/ for detailed information

---

## Expected Impact

### Token Reduction Estimate
| Content Type | Current Lines | Target Lines | Reduction |
|-------------|---------------|---------------|-------------|
| Role examples | ~300 lines | ~150 lines | 50% |
| OTP patterns | ~800 lines | ~400 lines | 50% |
| Overlap removal | ~400 lines | ~50 lines | 87% |

### Quality Improvement
- **Single source of truth**: No conflicting guidance
- **Clear hierarchy**: Easy to find relevant information
- **Reduced complexity**: Focused, role-specific files

---

## Next Steps

1. **Execute Task 2.1**: Remove redundant examples from roles/
2. **Execute Task 2.2**: Add cross-reference links
3. **Execute Task 2.3**: Consolidate OTP content in skills/
4. **Execute Task 2.4**: Update documentation references

---

**Ready to proceed with Task 2.1**: Remove redundant examples from `roles/architect.md`?