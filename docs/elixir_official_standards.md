# Elixir Official Standards

**Purpose**: Reference guide for official Elixir community standards and guidelines.

## Official Sources

1. **Elixir Library Guidelines**: https://hexdocs.pm/elixir/library-guidelines.html
2. **Elixir Naming Conventions**: https://hexdocs.pm/elixir/naming-conventions.html
3. **Community Style Guide**: https://github.com/christopheradams/elixir_style_guide
4. **Elixir Writing Documentation**: https://hexdocs.pm/elixir/writing-documentation.html

---

## Library Guidelines

### Project Structure

```elixir
# Standard project structure
my_app/
├── lib/           # Source code
│   └── my_app/
├── test/          # Test files
├── mix.exs        # Build configuration
└── README.md       # Documentation
```

### Publishing Requirements

1. **Semantic Versioning**: Use MAJOR.MINOR.PATCH format
2. **Code Formatting**: Run `mix format` (standard community style)
3. **Write Tests**: Elixir ships with ExUnit, use it
4. **Write Documentation**: Use ExDoc for API documentation
5. **Choose License**: Common licenses are MIT and Apache 2.0

### Code Standards

- **Follow Mix conventions**: Use `mix new` to scaffold projects
- **Use snake_case**: Project names, variable names, function names
- **Use modules**: Logical organization of code
- **Documentation first**: `@moduledoc` and `@doc` for public functions

---

## Naming Conventions

### Project Names

```elixir
# GOOD - snake_case
defmodule MyApp.Accounts
defmodule MyProject.Web

# BAD - camelCase or mixed
defmodule my_app.accounts
defmodule MyProjectWeb
```

### Module Names

```elixir
# GOOD - PascalCase
defmodule MyApp.Accounts
defmodule MyApp.Accounts.User

# BAD - snake_case
defmodule my_app.accounts
defmodule my_app.accounts.user
```

### Function Names

```elixir
# GOOD - snake_case
def create_user(attrs)
def list_users(filter)
def calculate_total(items)

# BAD - camelCase
def createUser(attrs)
def listUsers(filter)
def calculateTotal(items)
```

### Variable Names

```elixir
# GOOD - snake_case
def process(user_data)
user_name = "John"
result_count = 10

# BAD - camelCase
def process(userData)
userName = "John"
resultCount = 10
```

### Atoms

```elixir
# GOOD - snake_case
:get_user_status
:handle_request
:timeout
:account_created
:network_error

# BAD - camelCase
:getUserStatus
:handleRequest
:timeOut
:accountCreated
:networkError
```

---

## Community Style Guide

### Key Guidelines

1. **Do not parenthesize single-line functions**:
```elixir
# GOOD
def func_name, do: result

# BAD
def func_name, do: (result)
```

2. **Use pipe operator for transformations**:
```elixir
# GOOD
result
|> step_one()
|> step_two()
|> step_three()

# BAD
result = step_two(step_one())
final = step_three(result)
```

3. **Use pattern matching instead of conditionals**:
```elixir
# GOOD
case result do
  {:ok, value} -> value
  {:error, reason} -> handle_error(reason)
  :timeout -> retry()
end

# BAD
if elem(result, 0) == :ok do
  value = elem(result, 1)
else
  reason = elem(result, 1)
  handle_error(reason)
end
```

4. **Avoid default arguments**:
```elixir
# GOOD
def process(user, opts \\ []) do
  # opts defaults to empty list
end

# BAD
def process(user) do
  # No way to customize
end
```

---

## Integration with ai-rules

### When to Use Official Standards

- **Library design**: Reference `docs/elixir_official_standards.md` for publishing guidelines
- **Naming conventions**: Follow official Elixir naming (snake_case projects/functions, PascalCase modules)
- **Documentation**: Use ExDoc for public API documentation
- **Code style**: Run `mix format` to match community formatting
- **Testing**: Use ExUnit as standard test framework

### Roles and Skills to Reference

- **Architect**: Use naming conventions when designing module structure
- **Orchestrator**: Follow naming conventions for all new code
- **Backend Specialist**: Reference style guide for code formatting
- **Reviewer**: Verify official standards compliance
- **Test Generation**: Use official testing practices

### Skills to Reference

- **api-design**: Use naming conventions for API design
- **test-generation**: Use official testing practices
- **otp-patterns**: Follow official naming conventions
- **git-workflow**: Follow community conventions for code documentation

---

## Best Practices Summary

1. **Project names**: snake_case (my_app, user_auth_system)
2. **Module names**: PascalCase (MyApp.Accounts, MyProject.Web)
3. **Function/variable names**: snake_case (create_user, list_users, user_data)
4. **Atoms**: snake_case (:user_created, :network_error)
5. **No unnecessary parentheses**: Single-line functions without parens
6. **Use pipe operator**: Transform data with `|>`
7. **Pattern matching**: Use case statements instead of if/else
8. **Documentation**: Add @moduledoc and @doc to public functions
9. **Code formatting**: Run mix format to match community style
10. **Testing**: Use ExUnit for all tests
