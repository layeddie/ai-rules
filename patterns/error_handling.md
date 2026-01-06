# Error Handling Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: Hexdocs + Elixir School + Medium (Kanishka) (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Handling exceptions and errors gracefully
- Using `try/rescue` vs pattern matching
- Managing tuple returns (`{:ok, result}`, `{:error, reason}`)
- Propagating errors through supervisors
- User-facing error messages

❌ **DON'T use this file when**:
- Using raw raises without proper error types
- Ignoring error tuples
- Silent failures without logging
- Catch-all exceptions that hide bugs

**See also**:
- `exunit_testing.md` - Error testing patterns
- `genserver.md` - GenServer error handling

---

## Pattern 1: Returning Tuple Results

**Concept**: Explicit success/error tuples

✅ **Example**:
```elixir
defmodule MyApp.UserService do
  def create_user(attrs) do
    case validate(attrs) do
      {:ok, valid_attrs} ->
        Repo.insert(valid_attrs)
        {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp validate(attrs) do
    if attrs[:email] =~ ~r/@/ do
      {:error, %{field: :email, message: "invalid email"}}
    else
      {:ok, attrs}
    end
end
```

**Reference**: Elixir School - Error Handling

---

## Pattern 2: Using `with` Statements

**Concept**: Chain operations with early exit

✅ **Example**:
```elixir
defmodule MyApp.DataProcessor do
  def process_file(path) do
    with {:ok, content} <- File.read(path),
         {:ok, parsed} <- parse(content),
         {:ok, result} <- transform(parsed) do
      save(result)
    else
      {:error, :file_not_found}
    end
  end
end
```

**When to use**: Sequential dependent operations

**Reference**: Elixir School

---

## Pattern 3: try/rescue for Exception Handling

**Concept**: Graceful error recovery

✅ **Example**:
```elixir
defmodule MyApp.ExternalService do
  def fetch_data(id) do
    try do
      HTTPClient.get("/api/data/#{id}")
    rescue
      e in RuntimeError ->
        Logger.error("Failed to fetch data: #{inspect(e)}")
        {:error, :fetch_failed}

      e in [ArgumentError, MatchError] ->
        {:error, :invalid_input}

      e ->
        {:error, :unknown_error}
    end
  end
end
```

**When to use**: External API calls, file operations

**Reference**: Medium - "Understanding Error Handling: Try/Rescue" (2025)

---

## Pattern 4: Raising Custom Errors

**Concept**: Type-safe error messages

✅ **Example**:
```elixir
defmodule MyApp.Errors do
  defexception UserNotFound, message: "User not found", key: :user_not_found

  defmodule MyApp.UserService do
  def get_user!(id) do
    case get_user(id) do
      {:ok, user} -> user
      {:error, :not_found} -> raise UserNotFound, id: id
    end
  end
end
```

**Reference**: Hexdocs `defexception` documentation

---

## Pattern 5: Error Logging

**Concept**: Structured error information

✅ **Example**:
```elixir
defmodule MyApp.Logger do
  require Logger

  def log_user_action(user, action) do
    Logger.info("User #{user.id} performed action: #{action}")

  def log_error(context, error) do
    Logger.error("Error in #{context}: #{inspect(error)}")
  end
end
```

**Best Practices**:
- Use Logger.info for informational messages
- Use Logger.warn for recoverable issues
- Use Logger.error for critical failures
- Include context (user IDs, request IDs) in error messages

**Reference**: Elixir Logger documentation

---

## Pattern 6: Supervisor Error Handling

**Concept**: Let supervisors manage child failures

✅ **Example**:
```elixir
defmodule MyApp.Worker do
  use GenServer

  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  def terminate(_reason, state) do
    Logger.warning("Worker terminating: #{inspect(_reason)}")
  end
end
```

**When to use**: GenServers with critical cleanup

**Reference**: `otp_supervisor.md` - Supervisor strategies

---

## Pattern 7: User-Facing Error Messages

**Concept**: Meaningful errors for users

✅ **Example**:
```elixir
defmodule MyAppWeb.ErrorView do
  use MyAppWeb, :view

  def render("404.html", _assigns) do
    ~H"""
    <h1>User Not Found</h1>
    <p>The requested user could not be found.</p>
    <p><a href="/">Return to home</a></p>
    """
  end

  def render("500.html", _assigns) do
    ~H"""
    <h1>Server Error</h1>
    <p>Something went wrong. Please try again.</p>
    """
  end
end
```

**Best Practices**:
- Use friendly, actionable error messages
- Include suggested actions for users
- Never expose internal implementation details
- Use appropriate HTTP status codes (404, 422, 500)

**Reference**: Phoenix documentation

---

## Pattern 8: Ash Error Handling

**Concept**: Ash provides structured error handling

✅ **Example**:
```elixir
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    domain: ["MyApp.Accounts"],
    extensions: [Ash.Policy.Authorizer]

  actions do
    create :default
    read :default
    update :default
    destroy :default
  end

  # Custom validation with Ash errors
  defp validate_email(changeset) do
    if changeset.changes.email =~ ~r/[^@]+/ do
      Ash.Changeset.add_error(changeset, :email, "must contain @ symbol")
    else
      changeset
    end
  end
end
```

**When to use**: Ash resource validation and policy errors

**Reference**: `ash_resources.md` - Ash resource patterns

---

## Testing Patterns for This File

### Unit Testing Error Cases

```elixir
test "returns error tuple for invalid input" do
  assert {:error, :invalid_email} = create_user(%{email: "bad"})
end

test "raises custom error" do
  assert_raise MyApp.Errors.UserNotFound, ~r/User not found with id: 1/
end

test "rescues runtime error" do
  assert {:ok, result} = safe_operation()
  assert {:error, :fetch_failed} = unsafe_operation()
end
```

### Integration Testing with Error Handling

```elixir
test "controller returns 404 for missing resource" do
  conn = get(conn, "/api/users/999")
  assert html_response(conn, 404)
  assert get_flash(conn, :error) =~ "not found"
end
```

---

## References

**Primary Sources**:
- Hexdocs - try, catch, rescue documentation
- Elixir School - Error Handling guides
- Medium - "Understanding Error Handling: Try/Rescue vs Try/Catch in JavaScript" (2025)

**Related Patterns**:
- `exunit_testing.md` - Error testing patterns
- `genserver.md` - GenServer error handling
- `phoenix_controllers.md` - Controller error handling

**Deep Dives**:
- Hexdocs Error documentation
- `skills/error-handling/SKILL.md` (if exists)
