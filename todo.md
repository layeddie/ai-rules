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
