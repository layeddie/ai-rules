# Task Completion Checklist for ai-rules

## Before Completing a Task

### Code Quality Checks
- [ ] **Format code**: Run `mix format`
- [ ] **Credo checks**: Run `mix credo --strict` (fix all warnings)
- [ ] **Type checking**: Run `mix dialyzer` (if PLTs available, fix all warnings)
- [ ] **No secrets**: Verify no `.env`, `.envrc`, credentials files committed

### Testing
- [ ] **All tests pass**: Run `mix test` (must pass)
- [ ] **Coverage goal met**: Run `mix test --cover` (target: >80%)
- [ ] **Edge cases tested**: Property-based tests for critical functions
- [ ] **Integration tests**: For multi-module features
- [ ] **OTP tests**: Use `start_supervised!/1`, not direct `start_link`

### Documentation
- [ ] **Module docs**: Add `@moduledoc` for new modules
- [ ] **Function docs**: Add `@doc` for public functions
- [ ] **Type specs**: Add `@spec` and `@type` where appropriate
- [ ] **Examples**: Include usage examples in docs
- [ ] **README updates**: If adding new features or changing architecture

### OTP Compliance (for Elixir projects)
- [ ] **Supervision trees**: Properly structured and documented
- [ ] **Named processes**: Use named processes for services
- [ ] **Restart strategies**: Document and appropriate for use case
- [ ] **Fault boundaries**: Clear separation of concerns
- [ ] **No blocking callbacks**: GenServer callbacks don't block

### Database (if applicable)
- [ ] **Migrations**: Created and tested
- [ ] **N+1 prevention**: Preloads in place for queries
- [ ] **Indexes**: Critical queries indexed
- [ ] **Schema docs**: Document schema fields and relationships

### Security
- [ ] **Input validation**: All user inputs validated
- [ ] **Authorization**: Policies in place for resources
- [ ] **No sensitive data**: No secrets in code or logs
- [ ] **SQL injection prevention**: Use Ecto properly

## Git Workflow

### Before Commit
- [ ] **Changes reviewed**: Review diff before committing
- [ ] **Atomic commits**: Each commit is focused and complete
- [ ] **Conventional format**: Use `feat:`, `fix:`, `refactor:`, etc.
- [ ] **Descriptive message**: Clear explanation of what and why

### Before Push
- [ ] **All checks pass**: Format, Credo, Dialyzer, Tests
- [ ] **No sensitive data**: No secrets in code
- [ ] **Branch up to date**: Rebase on latest main if needed
- [ ] **Feature complete**: All acceptance criteria met

### Pull Request
- [ ] **Clear description**: What, why, how
- [ ] **Test plan**: How to verify changes
- [ ] **Screenshots**: For UI changes
- [ ] **Breaking changes**: Documented if any
- [ ] **Related issues**: Linked to issues

## Multi-Session Workflow

### Plan Session Completion
- [ ] **Architecture documented**: In `project_requirements.md`
- [ ] **File structure planned**: Clear directory/module organization
- [ ] **Supervision tree designed**: Fault boundaries defined
- [ ] **Domain boundaries**: Clear separation of concerns
- [ ] **Technology choices**: Documented and justified

### Build Session Completion
- [ ] **Tests written first**: TDD approach (Red, Green, Refactor)
- [ ] **Implementation complete**: Matches architectural plan
- [ ] **All tests pass**: Including edge cases
- [ ] **Code quality**: Format, Credo, Dialyzer clean
- [ ] **Integration complete**: Works with existing code

### Review Session Completion
- [ ] **Code review done**: Specific, actionable feedback
- [ ] **OTP patterns verified**: Supervision, GenServer best practices
- [ ] **Performance checked**: N+1 queries, bottlenecks
- [ ] **Test coverage analyzed**: Meets goals
- [ ] **Recommendations documented**: For improvements

## Tool-Specific Checks

### mgrep Usage
- [ ] **Specific queries**: Not too broad
- [ ] **Results limited**: When appropriate
- [ ] **Path filtering**: Used for large codebases
- [ ] **Free tier respected**: Within usage limits

### Serena MCP Usage
- [ ] **Symbol-aware editing**: Used when possible
- [ ] **Files read before edit**: Context understood
- [ ] **Semantic search used**: For complex refactors
- [ ] **No conflicting LSP**: Only one active at a time

### OpenCode Usage
- [ ] **Correct mode**: Plan/Build/Review as appropriate
- [ ] **Tool restrictions respected**: Read-only in plan/review
- [ ] **Session documented**: Clear purpose and outcome
- [ ] **Files updated**: `project_requirements.md` current

## Final Verification

### For New Features
- [ ] **Feature works**: Manual testing successful
- [ ] **Tests comprehensive**: Unit, integration, property-based
- [ ] **Docs complete**: Module, function, usage examples
- [ ] **No regressions**: Existing tests still pass
- [ ] **Performance acceptable**: No significant slowdown

### For Bug Fixes
- [ ] **Bug fixed**: Original issue resolved
- [ ] **Root cause addressed**: Not just symptoms
- [ ] **Tests added**: Prevent regression
- [ ] **No side effects**: Other functionality intact
- [ ] **Docs updated**: If behavior changed

### For Refactors
- [ ] **Behavior preserved**: No functional changes
- [ ] **Tests still pass**: No test updates needed
- [ ] **Code improved**: Clearer, faster, or more maintainable
- [ ] **Docs current**: Reflect new structure
- [ ] **No dead code**: Removed unused code

## Project-Specific Checks

### Phoenix + Ash Projects
- [ ] **Ash resources**: Schema, validations, actions defined
- [ ] **Policies**: Authorization rules in place
- [ ] **LiveView**: State in Ash, thin controllers
- [ ] **Migrations**: Database schema migrations created

### Nerves Projects
- [ ] **Firmware builds**: Compiles for target
- [ ] **Hardware interfaces**: Proper GenServer patterns
- [ ] **Deployment config**: Target-specific configuration
- [ ] **Testing strategy**: Hardware simulation/mocking

### Library Projects
- [ ] **Public API**: Clear and well-documented
- [ ] **Examples**: Usage examples provided
- [ ] **Hex docs**: Generated and complete
- [ ] **Version compatibility**: Elixir/OTP versions documented

## Ready to Complete

When all applicable items are checked:
- ✅ **Commit changes**: With descriptive message
- ✅ **Push to branch**: Feature branch
- ✅ **Create/update PR**: With complete description
- ✅ **Request review**: Assign reviewers
- ✅ **Update docs**: If needed
