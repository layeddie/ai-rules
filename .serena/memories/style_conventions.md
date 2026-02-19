# Style and Conventions for ai-rules

## Elixir Code Style

### General Principles
- Follow official Elixir formatting (`mix format`)
- Use `mix credo --strict` for quality checks
- Keep one module per file (unless documented reason)
- Prefer pattern matching over nested conditionals
- Use `{:ok, result}` / `{:error, reason}` tuples for fallible operations
- Avoid exceptions for normal control flow

### Naming Conventions
- **Modules**: PascalCase (e.g., `UserService`, `Accounts.User.Register`)
- **Functions**: snake_case (e.g., `create_user`, `authenticate_user`)
- **Variables**: snake_case (e.g., `user_id`, `current_user`)
- **Atoms**: snake_case (e.g., `:ok`, `:error`, `:user_created`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `@max_retries`, `@timeout`)

### OTP Patterns
- **GenServer**: Clear separation between client API and server callbacks
- **Named processes**: Use named processes for long-running services
- **Supervision trees**: Document restart strategies and fault boundaries
- **Registry**: Use for dynamic process naming and discovery

### Domain Resource Action (DRA)
- **Domains**: Organize by business domain (e.g., `Accounts`, `Payments`)
- **Resources**: Schema + validations (e.g., `User`, `Transaction`)
- **Actions**: Single responsibility functions (e.g., `Register`, `Create`)
- **Policies**: Authorization per resource
- **Notifiers**: Side-effect handlers (email, pubsub)

## Testing Conventions

### Test Organization
- Mirror source structure in tests (`test/` mirrors `lib/`)
- Use `start_supervised!/1` for supervised process lifecycle
- Avoid sleep-based synchronization
- Prefer monitors/assertions over timing sleeps

### Test Naming
- Test files: `<module>_test.exs` (e.g., `user_service_test.exs`)
- Test modules: `<Module>Test` (e.g., `UserServiceTest`)
- Test names: descriptive with "test" prefix (e.g., `test "registers user with valid attrs"`)

### Test Types
- **Unit**: Test individual functions/modules
- **Integration**: Test multiple modules together
- **Property-based**: Use StreamData or PropCheck for edge cases
- **E2E**: Test critical user journeys

## Documentation Conventions

### Module Documentation
- Use `@moduledoc` for module-level documentation
- Use `@doc` for function-level documentation
- Include examples in documentation
- Document types with `@spec` and `@type`

### Code Comments
- Prefer clear code over excessive comments
- Use comments to explain "why", not "what"
- Document complex business logic
- Add TODO/FIXME for future work

## File Organization

### Directory Structure
```
lib/
├── [app]/              # Application + supervision
│   ├── application.ex  # Top-level supervisor
│   ├── registry/       # Registry + DynamicSupervisor
│   └── support/        # Pure helpers (no IO/side effects)
└── [app]_ash/          # Ash Domain Resource Action
    ├── domains/        # Domain boundaries
    ├── resources/      # Ash Resources
    ├── actions/        # Ash Actions
    ├── policies/       # Authorization
    └── notifiers/      # Side-effects
```

### Module Organization
- One module per file
- Group related modules in subdirectories
- Keep modules focused (single responsibility)
- Avoid deep nesting (max 3-4 levels)

## Anti-Patterns to Avoid

### OTP Anti-Patterns
- ❌ Blocking GenServer callbacks
- ❌ Overusing shared state via ETS
- ❌ Mixing concerns in modules
- ❌ Ignoring supervision strategies
- ❌ Using PID dependencies

### Elixir Anti-Patterns
- ❌ Using `String.to_atom/1` on user input
- ❌ Relying on inner rebinding from `if/case/cond`
- ❌ Using map-access syntax on structs (`struct[:field]`)
- ❌ Using exceptions for normal control flow
- ❌ N+1 queries (always preload/index)

## Quality Checks

### Code Quality
```bash
mix format           # Format code
mix credo --strict   # Quality checks
mix dialyzer         # Type checking
```

### Test Quality
- Coverage goal: >80% (or project goal)
- Run tests with coverage: `mix test --cover`
- Use property-based testing for edge cases
- Test OTP processes properly (not direct `start_link`)

## Git Conventions

### Commit Messages
- Use conventional commit format
- Examples: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`
- Keep commits focused and atomic
- Reference issues when applicable

### Branch Naming
- Feature branches: `feature/<short-description>`
- Fix branches: `fix/<short-description>`
- Refactor branches: `refactor/<short-description>`
- Use lowercase and hyphens

## Tool-Specific Conventions

### mgrep
- Use for conceptual/semantic queries
- Use ripgrep for exact pattern matching
- Be specific with queries
- Limit results when appropriate

### Serena MCP
- Use for semantic navigation/editing
- Use symbolic tools when possible
- Prefer symbol-aware editing over text replacement
- Read files before editing

### OpenCode
- Use appropriate mode (plan/build/review)
- Respect tool restrictions per mode
- Use `AI_RULES_SILENT=1` to suppress banner noise
