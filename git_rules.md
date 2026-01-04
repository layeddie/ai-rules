# Git Workflow Rules for OpenCode

**Version**: 1.0.0
**Last Updated**: 2026-01-03
**Repository**: https://github.com/layeddie/ai-rules

---

## Overview

This document defines the Git workflow for OpenCode projects. All agents must follow these rules when performing Git operations.

## Repository Configuration

### Current Repositories

- **ai-rules**: https://github.com/layeddie/ai-rules (public)
- **tensioner**: https://github.com/layeddie/tensioner (public)

### Repository Isolation

- **ai-rules** and **tensioner** are completely separate projects
- No tensioner references should exist in ai-rules repository
- No ai-rules references should exist in tensioner repository (except as symlink/submodule)
- Each repository has its own Git history and development workflow

---

## Branch Strategy

### Main Branches

- **main**: Production-ready code, always deployable
- **develop**: Integration branch (optional, for projects requiring staging)

### Feature Branches

- **feature/***: New features and functionality
- **fix/***: Bug fixes
- **hotfix/***: Critical fixes for production (branch from main)
- **refactor/***: Code refactoring
- **docs/***: Documentation updates
- **chore/***: Maintenance tasks, dependencies, configuration

### Branch Naming Convention

```
feature/add-git-workflow
fix/resolve-merge-conflict
hotfix/critical-bug-in-production
refactor/optimize-database-queries
docs/update-readme
chore/update-dependencies
```

---

## Git Workflow

### 1. Feature Development Workflow

```bash
# Step 1: Update main branch
git checkout main
git pull origin main

# Step 2: Create feature branch
git checkout -b feature/descriptive-name

# Step 3: Make changes and test
# ... development work ...

# Step 4: Stage and commit changes
git add .
git commit -m "feat: add feature description"

# Step 5: Push to GitHub
git push -u origin feature/descriptive-name

# Step 6: Create pull request
gh pr create --title "Add feature description" \
  --body "Implements feature X, closes #123" \
  --reviewer layeddie

# Step 7: Request review and merge after approval
gh pr merge --squash

# Step 8: Cleanup branches
git checkout main
git pull origin main
git branch -d feature/descriptive-name
git push origin --delete feature/descriptive-name
```

### 2. Bug Fix Workflow

```bash
# For non-critical bugs (branch from main)
git checkout main
git pull origin main
git checkout -b fix/bug-description

# For critical bugs (hotfix)
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug

# Fix, test, commit, push, create PR
# ... same as feature workflow ...
```

### 3. Code Review Workflow

```bash
# Review PR
gh pr view <pr-number>

# Add review comment
gh pr review <pr-number> --comment -b "Suggestion: use conventional commits"

# Approve PR
gh pr review <pr-number> --approve

# Request changes
gh pr review <pr-number> --request-changes -b "Please add tests"

# Merge approved PR
gh pr merge --squash
```

---

## Commit Conventions

### Conventional Commit Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Commit Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style (formatting, no logic change)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Add/update tests
- **chore**: Build process, dependencies, configuration
- **ci**: CI/CD changes

### Commit Examples

```bash
# Example
git commit -m "feat: add git specialist role to ai-rules"

# Fix
git commit -m "fix: resolve merge conflict in git_rules.md"

# Documentation
git commit -m "docs: update README with git workflow section"

# Refactoring
git commit -m "refactor: move tensioner to separate repository"

# Testing
git commit -m "test: add integration tests for git workflow"

# Chore
git commit -m "chore: update dependencies in mix.exs"
```

### Commit Guidelines

- ✅ Use present tense ("add" not "added")
- ✅ Keep subject line under 50 characters
- ✅ Start subject with lowercase letter (after type:)
- ✅ Do not end subject with period
- ✅ Wrap body at 72 characters
- ✅ Use footer to reference issues ("Closes #123")
- ❌ No generic commits ("update", "fix bug")
- ❌ No committing sensitive data
- ❌ No committing build artifacts

---

## Pull Request Guidelines

### PR Title Format

```
<type>: <subject>
```

Examples:
- "feat: add git workflow integration"
- "fix: resolve merge conflict in git_rules.md"
- "docs: update README with git workflow section"

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional change)

## Related Issues
Closes #<issue_number>
Fixes #<issue_number>
Related to #<issue_number>

## Testing
Describe how this was tested:
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing performed
- [ ] Code reviewed by [reviewer]

## Checklist
- [ ] Follows git_rules.md conventions
- [ ] Conventional commit message format used
- [ ] Code is properly formatted
- [ ] Tests pass (`mix test` or equivalent)
- [ ] No merge conflicts expected
- [ ] Documentation updated if needed
- [ ] No sensitive data committed
```

### PR Merge Strategy

- **Feature branches**: Use squash merge (`--squash`)
- **Hotfix branches**: Use squash merge (`--squash`)
- **Documentation branches**: Use squash merge (`--squash`)
- **Releases**: Use merge commit (`--merge`) to preserve release history

---

## Repository Specific Rules

### ai-rules Repository

**Purpose**: AI rules, roles, skills, and templates for Elixir/BEAM development

**Structure**:
```
ai-rules/
├── roles/              # Role definitions (architect, orchestrator, git-specialist)
├── skills/             # Technical skills (otp-patterns, git-workflow)
├── tools/              # Tool configurations (opencode, claude, cursor)
├── templates/          # Project templates (phoenix-ash-liveview, nerves)
├── configs/            # Configuration templates (project_requirements.md)
├── scripts/            # Helper scripts (init_project.sh, setup_opencode.sh)
├── AGENTS.md           # Agent guidelines
├── git_rules.md        # This file
└── README.md           # Project documentation
```

**Rules**:
- ✅ No tensioner project references
- ✅ No other project dependencies in main branch
- ✅ Clean git history (squash merge feature branches)
- ✅ Use submodules for project-specific configurations
- ❌ No committing large binary files
- ❌ No committing sensitive data (.env, credentials)

### Tensioner Repository

**Purpose**: Electronic string tensioner system built with Elixir/Nerves

**Structure**:
```
tensioner/
├── lib/                # Application code
├── test/               # Test files
├── config/             # Configuration files
├── rel/                # Release configuration
├── rootfs_overlay/     # Nerves filesystem overlay
├── mix.exs             # Mix configuration
├── README.md           # Project documentation
└── ai-rules/           # Symlink to ../ai-rules (gitignored)
```

**Rules**:
- ✅ Symlink to ai-rules (not submodule)
- ✅ ai-rules in .gitignore
- ✅ Clean git history
- ✅ Follow Nerves project conventions
- ❌ No ai-rules files committed
- ❌ No committing sensitive data

---

## Automation Rules

### OpenCode Build Mode

When implementing features in Build Mode:

1. **Before Making Changes**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/<feature-name>
   ```

2. **After Implementing Feature**:
   ```bash
   git status
   git add .
   git commit -m "feat: <feature description>"
   git push -u origin feature/<feature-name>
   ```

3. **Code Review**:
   ```bash
   gh pr create --title "<feature title>" --body "<description>"
   ```

4. **After Review**:
   ```bash
   gh pr merge --squash
   git checkout main
   git pull origin main
   git branch -d feature/<feature-name>
   ```

### OpenCode Plan Mode

- Plan mode is **read-only**
- No git operations required
- Focus on architecture and design

### OpenCode Review Mode

- Review mode is **analysis-only**
- Use `gh pr review` to review PRs
- Provide specific, actionable feedback

---

## Git Hooks

### Pre-commit Hook (Optional)

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Format code
mix format

# Run tests
mix test --max-failures=1

# Check exit status
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

### Commit-msg Hook (Optional)

```bash
#!/bin/sh
# .git/hooks/commit-msg

# Enforce conventional commits
commit_regex='^(feat|fix|docs|style|refactor|test|chore|ci|perf)(\(.+\))?: .{1,50}'
error_msg="Aborting commit. Your commit message is not formatted correctly."

if ! grep -qE "$commit_regex" "$1"; then
    echo "$error_msg" >&2
    exit 1
fi
```

---

## Merge Conflict Resolution

### Conflicting Files

When merge conflicts occur:

1. Identify conflicted files:
   ```bash
   git status
   ```

2. Open conflicted files and look for markers:
   ```
   <<<<<<< HEAD
   Your changes
   =======
   Incoming changes
   >>>>>>> feature/branch-name
   ```

3. Resolve conflicts by editing files

4. Mark as resolved:
   ```bash
   git add <conflicted-file>
   ```

5. Complete merge:
   ```bash
   git commit -m "fix: resolve merge conflict in <file>"
   ```

### Conflict Prevention

- Pull latest changes before starting work
- Communicate with collaborators
- Keep feature branches short-lived
- Create PRs early to identify conflicts

---

## Branch Protection Rules

### Main Branch Protection

```bash
# Configure branch protection (recommended)
gh api repos/layeddie/<repo>/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["ci"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null \
  --field allow_deletions=false \
  --field allow_force_pushes=false
```

### Branch Protection Settings

- **Require pull request reviews before merging**: Yes (1 reviewer)
- **Require status checks to pass before merging**: Yes
- **Require branches to be up to date before merging**: Yes
- **Restrict who can push to main**: Yes (maintainers)
- **Allow deletions**: No
- **Allow force pushes**: No

---

## Git Submodules (Optional)

### Adding Submodule

```bash
# Add ai-rules as submodule (optional)
git submodule add https://github.com/layeddie/ai-rules.git ai-rules

# Commit submodule
git add .gitmodules
git commit -m "chore: add ai-rules as submodule"
```

### Cloning with Submodules

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/layeddie/tensioner.git

# Or initialize separately
git clone https://github.com/layeddie/tensioner.git
cd tensioner
git submodule update --init --recursive
```

### Updating Submodule

```bash
# Update submodule to latest
git submodule update --remote ai-rules

# Commit submodule update
git add ai-rules
git commit -m "chore: update ai-rules submodule"
```

---

## Git Best Practices

### Dos

- ✅ Create feature branches for all changes
- ✅ Use conventional commits
- ✅ Write descriptive commit messages
- ✅ Create PRs for code review
- ✅ Request review before merging
- ✅ Use squash merge for feature branches
- ✅ Delete merged branches promptly
- ✅ Pull latest changes before starting work
- ✅ Run tests before committing
- ✅ Resolve conflicts promptly

### Don'ts

- ❌ Commit directly to main
- ❌ Push to main without PR review
- ❌ Use force push to main
- ❌ Commit sensitive data
- ❌ Commit large binary files
- ❌ Leave stale branches
- ❌ Merge unreviewed code
- ❌ Ignore merge conflicts
- ❌ Skip tests before committing

---

## Troubleshooting

### Repository Not Found

```bash
# Check remote configuration
git remote -v

# Update remote URL
git remote set-url origin https://github.com/layeddie/ai-rules.git
```

### Authentication Issues

```bash
# Check GitHub CLI auth
gh auth status

# Re-authenticate
gh auth logout
gh auth login
```

### Merge Conflicts

```bash
# View conflicts
git status

# Abort merge if needed
git merge --abort

# Use merge tool
git mergetool
```

### Submodule Issues

```bash
# Reinitialize submodules
git submodule deinit --all
git submodule update --init --recursive

# Sync submodule URLs
git submodule sync --recursive
```

---

## References

- **Git Specialist Role**: `roles/git-specialist.md`
- **Git Workflow Skill**: `skills/git-workflow/SKILL.md`
- **OpenCode Configuration**: `tools/opencode/opencode.json`
- **Agent Guidelines**: `AGENTS.md`
- **GitHub CLI Docs**: https://cli.github.com/manual/

---

## Summary

All Git operations in OpenCode projects must follow these rules:

1. **Repository Isolation**: Separate projects with clean histories
2. **Feature Branch Workflow**: Create branches, PRs, and squash merge
3. **Conventional Commits**: Use standardized commit format
4. **Code Review**: Always use PRs for review
5. **Branch Protection**: Protect main branch with rules
6. **Clean History**: Squash merge feature branches
7. **No Direct Commits**: Never commit directly to main
8. **Test Before Commit**: Always run tests before committing
9. **Cleanup**: Delete merged branches promptly
10. **Security**: Never commit sensitive data

**Violations of these rules will result in rejected pull requests.**

---

**End of git_rules.md**
