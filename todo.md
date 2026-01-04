# TODO: Deferred Tasks

**Created**: 2026-01-04
**Purpose**: Track low-priority tasks deferred from initial refactor

---

## Low Priority Tasks

### 1. Correct .gitignore Pattern
- **Current**: `.ai_rules` pattern in generated .gitignore
- **Issue**: Should be `ai-rules` pattern after rename
- **Action**: Update `scripts/init_project.sh` .gitignore generation (line 87-113)
- **Status**: ⏸️ Deferred per user request
- **Priority**: Low

### 2. Add CONTRIBUTING.md
- **Purpose**: Guidelines for external contributors
- **Location**: Root of ai-rules repository
- **Sections to include**:
  - Code of conduct
  - Development workflow
  - Pull request process
  - Commit message conventions
  - Testing requirements
  - Issue reporting guidelines
- **Status**: ⏸️ Deferred per user request (Task 6 from review)
- **Priority**: Low

### 3. Complete Template Implementation
- **phoenix-basic**: Create basic Phoenix template files
  - Basic router
  - Sample controller
  - Simple endpoint
  - Mix.exs template
- **elixir-library**: Create library template files
  - Public API structure
  - Mix.exs for library
  - Basic test setup
- **Status**: ⏸️ Deferred per user request
- **Priority**: Low

### 4. GitHub Pages Documentation
- **Purpose**: Static documentation website
- **Action**: Configure GitHub Pages from ai-rules repository
- **Status**: ⏸️ Not started
- **Priority**: Low

### 5. Release Tags and Versioning
- **Purpose**: Semantic versioning for ai-rules
- **Action**: 
  - Establish version number scheme (v1.0.0, v1.1.0, etc.)
  - Create release notes template
  - Add GitHub Actions for automatic releases
- **Status**: ⏸️ Not started
- **Priority**: Low

### 6. Additional Documentation Enhancements
- **Project examples**: Add sample projects using ai-rules
- **Video tutorials**: Create short demo videos
- **Troubleshooting guide**: Expand troubleshooting section
- **Performance benchmarks**: Add benchmark data for tools
- **Status**: ⏸️ Not started
- **Priority**: Low

---

## Completed Tasks (Moved from TODO)

### ✅ Rename .ai_rules to ai-rules
- **Date**: 2026-01-04
- **Branch**: refactor/rename-ai-rules-paths
- **Commits**: b87f894, 59e18d4, 1152f57, a1d5632, ede1591, 1dde301, c538d83, 503dcd4, 6dedea9, 56beb2c, 8f1e40a
- **Status**: Complete

### ✅ Remove Hardcoded Local Paths
- **Date**: 2026-01-04
- **Branch**: refactor/rename-ai-rules-paths
- **Files updated**: 30+ files
- **Status**: Complete

### ✅ Fix Template Directory Handling
- **Date**: 2026-01-04
- **Branch**: refactor/rename-ai-rules-paths
- **Action**: Added graceful handling for empty template directories
- **Status**: Complete

---

## Notes

- Items 1 and 2 were explicitly deferred by user request
- All deferred tasks are low priority and will be addressed in future PRs
- Users can manually update .gitignore pattern as workaround for task 1
- CONTRIBUTING.md can be added when external contributors start participating
- Template implementations (phoenix-basic, elixir-library) will be added as needed

---

## Next Steps for Deferred Tasks

1. **Evaluate Priority**: Reassess task priority based on user feedback
2. **Create Separate Branch**: Each deferred task should have its own feature branch
3. **Follow Git Rules**: Use conventional commits, create PRs, squash merge
4. **Update TODO**: Mark tasks as complete when finished

---

**End of TODO**
## Low Priority Tasks

### 1. Correct .gitignore Pattern
- **Current**: `.ai_rules` pattern in generated .gitignore
- **Issue**: Should be `ai-rules` pattern after rename
- **Action**: Update `scripts/init_project.sh` .gitignore generation (line 87-113)
- **Status**: ⏸️ Deferred per user request
- **Priority**: Low

### 2. Add CONTRIBUTING.md
- **Purpose**: Guidelines for external contributors
- **Location**: Root of ai-rules repository
- **Sections to include**:
  - Code of conduct
  - Development workflow
  - Pull request process
  - Commit message conventions
  - Testing requirements
  - Issue reporting guidelines
- **Status**: ⏸️ Deferred per user request (Task 6 from review)
- **Priority**: Low

### 3. Complete Template Implementation
- **phoenix-basic**: Create basic Phoenix template files
  - Basic router
  - Sample controller
  - Simple endpoint
  - Mix.exs template
- **elixir-library**: Create library template files
  - Public API structure
  - Mix.exs for library
  - Basic test setup
- **Status**: ⏸️ Deferred per user request
- **Priority**: Low

### 4. GitHub Pages Documentation
- **Purpose**: Static documentation website
- **Action**: Configure GitHub Pages from ai-rules repository
- **Status**: ⏸️ Not started
- **Priority**: Low

### 5. Release Tags and Versioning
- **Purpose**: Semantic versioning for ai-rules
- **Action**:
  - Establish version number scheme (v1.0.0, v1.1.0, etc.)
  - Create release notes template
  - Add GitHub Actions for automatic releases
- **Status**: ⏸️ Not started
- **Priority**: Low

### 6. Additional Documentation Enhancements
- **Project examples**: Add sample projects using ai-rules
- **Video tutorials**: Create short demo videos
- **Troubleshooting guide**: Expand troubleshooting section
- **Performance benchmarks**: Add benchmark data for tools
- **Status**: ⏸️ Not started
- **Priority**: Low

---

## Completed Tasks (Moved from TODO)

### ✅ Rename .ai_rules to ai-rules
- **Date**: 2026-01-04
- **Branch**: refactor/rename-ai-rules-paths
- **Commits**: b87f894, 59e18d4, 1152f57, a1d5632, ede1591, 1dde301, c538d83, 503dcd4, 6dedea9, 56beb2c, 8f1e40a
- **Status**: Complete

### ✅ Remove Hardcoded Local Paths
- **Date**: 2026-01-04
- **Branch**: refactor/rename-ai-rules-paths
- **Files updated**: 30+ files
- **Status**: Complete

### ✅ Fix Template Directory Handling
- **Date**: 2026-01-04
- **Branch**: refactor/rename-ai-rules-paths
- **Action**: Added graceful handling for empty template directories
- **Status**: Complete

### ✅ Add HTML/CSS Foundation to Frontend Specialist
- **Date**: 2026-01-04
- **Branch**: refactor/html-css-foundation
- **Commits**: 730754b
- **Files changed**: 465 insertions(+), 229 deletions(-)
- **Status**: Complete

---

## New Tasks (Added 2026-01-04)

### 7. Add Nix DevShell Guide
- **Date**: 2026-01-04
- **Branch**: feat/nix-devshell-igniter-integration
- **Description**: 
  - Add "Version Flexibility" section to `tools/nix/README.md`
  - Create `skills/nix/SKILL.md` with comprehensive Nix fundamentals
  - Create `roles/nix-specialist.md` for Nix environment specialist
- Document versioning strategies (Flakes, devshell overrides, ASDF integration)
  - Integrate Igniter guidance into Architect/Orchestrator roles
- Add MLX GPU configuration examples
  - Document cross-platform Nix usage (macOS, Linux, NixOS)
  - Add troubleshooting guide for common Nix issues
- **Action**: 
  - Update `tools/nix/README.md` (608 lines → 761 lines)
  - Create `skills/nix/SKILL.md` (594 lines)
  - Create `roles/nix-specialist.md` (304 lines)
  - Update `roles/architect.md` with Nix specialist consultation section
  - Update `roles/orchestrator.md` with Igniter integration workflow
  - Update `skills/api-design/SKILL.md` with Igniter compatibility guidance
- **Files Created/Modified**: 5 files (total ~2,620 lines added)
- **Status**: Complete

### 8. Add Ash Igniter How-To Guide
- **Date**: 2026-01-04
- **Branch**: feat/nix-devshell-igniter-integration
- **Description**:
  - Create `docs/igniter-how-to.md` as standalone documentation
  - Cover Igniter prerequisites, quick start, integration with ai-rules
  - Document learning phase workflows
  - Document debugging phase workflows
  - Integrate with Nix specialist consultation (version compatibility)
  - Add best practices for using Igniter with TDD workflow
  - Cover common issues and troubleshooting
  - Add key resources (Ash Igniter, Phoenix Storybook, Official Ash docs)
- **Action**:
  - Create `docs/igniter-how-to.md` (195 lines)
  - Integrate guidance into Architect and Orchestrator roles (already done in Task 7)
  - Add key resources to relevant skills (already done in Task 7)
- **Files Created**: 1 file (195 lines)
- **Status**: Complete

### 9. Add Key Resources to HTML/CSS Skill
- **Date**: 2026-01-04
- **Branch**: feat/nix-devshell-igniter-integration
- **Description**:
  - Update `skills/html-css/SKILL.md` with additional key resources
  - Add Phoenix Storybook reference for LiveView/Phoenix learning
  - Add Ash Igniter reference for Ash/HTML integration
  - Add Elixir Guides and WCAG 2.2 documentation links
  - Add MDN Web Docs for HTML/CSS best practices
  - Add accessibility resources (A11y Project, inclusive design)
  - Add Tailwind vs Semantic CSS comparison reference
- **Action**:
  - Update `skills/html-css/SKILL.md` with "Key Resources" section
  - Add Phoenix Storybook link
  - Add Ash Igniter link
  - Add Elixir Guides link
  - Add WCAG 2.2 link
  - Add A11y Project link
  - Add inclusive design link
  - Add Tailwind vs Semantic CSS link
- **Files Modified**: 1 file (15 lines added to footer)
- **Status**: Complete

---

## Notes

- Items 1 and 2 were explicitly deferred by user request
- All deferred tasks are low priority and will be addressed in future PRs
- Users can manually update .gitignore pattern as workaround for task 1
- CONTRIBUTING.md can be added when external contributors start participating
- Template implementations (phoenix-basic, elixir-library) will be added as needed
- Igniter is best for learning Ash Framework interactively
- Nix provides flexible versioning to support both stable and latest features
- Key resources added to HTML/CSS skill for comprehensive frontend and Ash reference

---

## Next Steps for Deferred Tasks

1. **Evaluate Priority**: Reassess task priority based on user feedback
2. **Create Separate Branch**: Each deferred task should have its own feature branch
3. **Follow Git Rules**: Use conventional commits, create PRs, squash merge
4. **Update TODO**: Mark tasks as complete when finished
