# ExUnit Testing Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: Elixir School + Medium (Jonny Eberhardt 2025) + Elixir Forum

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Writing unit tests for Elixir code
- Testing GenServers and supervised processes
- Integration testing with Phoenix
- Using fixtures and factories
- Mocking external dependencies

❌ **DON'T use this file when**:
- Testing simple functions (use ExUnit directly)
- Testing with frameworks other than ExUnit

**See also**:
- `genserver.md` - GenServer testing patterns
- `error_handling.md` - Exception testing patterns

---

## Pattern 1: Async vs Synchronous Tests

**Problem**: Async tests can interfere with shared state

✅ **Solution**: Use `async: true` with caution

```elixir
defmodule AsyncTest do
  use ExUnit.Case, async: true  # OK for stateless operations

  test "concurrent operations" do
    Task.async(fn -> MyModule.do_work() end)
    Task.async(fn -> MyModule.do_other_work() end)
  end
end

# For tests with shared state, use async: false
defmodule StatefulTest do
  use ExUnit.Case, async: false  # Important: Don't use async

  test "sequential operations" do
    result = MyModule.do_sequential_work()
    assert result == :expected
  end
end
```

**Reference**: Elixir School - Testing guides

---

## Pattern 2: setup and teardown

**Problem**: Repeating setup/teardown code across tests

✅ **Solution**: Use callbacks for reusable setup

```elixir
defmodule DatabaseTest do
  use ExUnit.DataCase

  setup_all do
    {:ok, user} = insert(:user, name: "Test User")
    {:ok, _tags} = insert_tags([:tag1, :tag2])
  end

  teardown_all do
    Repo.delete_all(User)
  end

  test "creates user with tags", %{user: user, tags: tags} do
    user_with_tags = MyModule.tag_user(user, tags)
    assert user_with_tags.tags == tags
  end
end
```

**Reference**: Hexdocs ExUnit documentation

---

## Pattern 3: describe for Organization

**Problem**: Related tests hard to find

✅ **Solution**: Use `describe` blocks

```elixir
defmodule UserServiceTest do
  use ExUnit.Case

  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{name: "Test User", email: "test@example.com"}
      {:ok, user} = UserService.create_user(attrs)
      assert user.name == "Test User"
    end

    test "returns error with invalid email" do
      attrs = %{name: "Test User", email: "invalid"}
      {:error, changeset} = UserService.create_user(attrs)
      assert "email" in Keyword.keys(Ash.Changeset.errors(changeset))
    end
  end

  describe "list_users/1" do
    test "returns all users" do
      users = UserService.list_users()
      assert length(users) > 0
    end
  end
end
```

**Reference**: Medium - "Break It Before It Breaks You: Advanced Testing Strategies"

---

## Pattern 4: Testing GenServers with Isolation

**Problem**: Testing GenServers requires controlled environment

✅ **Solution**: Use `start_supervised!` and `stop_supervised`

```elixir
defmodule CounterServerTest do
  use ExUnit.Case, async: false  # Important: Don't use async

  setup do
    {:ok, pid} = start_supervised!(CounterServer, 0)
    %{pid: pid}
  end

  test "increments counter", %{pid: pid} do
    assert CounterServer.value(pid) == 0
    CounterServer.increment(pid)
    assert CounterServer.value(pid) == 1
  end

  teardown do
    stop_supervised(CounterServer)
  end
end
```

**Key Principles**:
- Use `async: false` for GenServer tests
- Start/stop via supervision, not direct `GenServer.start_link`
- Test state transitions, not just API surface

**Reference**: `docs/genserver_testing.txt` (Freshcode.it guide)

---

## Pattern 5: Integration Testing with Phoenix

**Problem**: Testing full request/response cycle

✅ **Solution**: Use Phoenix.ConnTest helpers

```elixir
defmodule PostControllerTest do
  use MyAppWeb.ConnCase

  test "GET /posts returns list", %{conn: conn} do
    conn = get(conn, ~p"/posts")
    assert html_response(conn, 200) =~ "Posts"
  end

  test "POST /posts creates post", %{conn: conn} do
    conn = post(conn, ~p"/posts", post: %{title: "Test Post", body: "Test content"})
    assert redirected_to(conn, ~p"/posts/test-post")
  end

  test "DELETE /posts deletes post", %{conn: conn} do
    post = insert(:post)
    conn = delete(conn, ~p"/posts/#{post.id}")
    assert response(conn, 204)
  end
end
```

**Reference**: Phoenix testing documentation

---

## Pattern 6: Using Factories and Fixtures

**Problem**: Hardcoded test data is fragile

✅ **Solution**: Create reusable factories

```elixir
defmodule MyApp.SupportFixtures do
  @moduledoc """
  Test helpers for creating entities.
  """

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{email: "user@example.com", name: "Test User"})
      |> MyApp.Accounts.User.changeset()
      |> Ash.create!()

    {:ok, user}
  end

  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{title: "Test Post", body: "Test content"})
      |> MyApp.Blog.Post.changeset()
      |> Ash.create!()

    {:ok, post}
  end
end

defmodule MyApp.AccountsTest do
  use Ash.DataCase

  setup do
    {:ok, user} = MyApp.SupportFixtures.user_fixture()
  end

  test "can access user attributes" do
    assert user.email == "user@example.com"
    assert user.name == "Test User"
  end
end
```

**Reference**: DevTalk - "Ash Framework: How to test changes to resources?" (2025)

---

## Pattern 7: Testing with Mocks

**Problem**: External dependencies cause flaky tests

✅ **Solution**: Use Mox or other mocking libraries

```elixir
defmodule MyApp.HTTPClientTest do
  use ExUnit.Case
  import Mox

  setup :verify_on_exit!, :set_mox_global
  setup :set_mox_from_context

  test "makes HTTP request", %{http_client: client} do
    expect(client, :get, fn url -> {:ok, "response"})
    assert MyApp.HTTPClient.get(client, "/api/data") == {:ok, "response"}
  end
end

defmock MyApp.HTTPClient do
  def get(_client, _url), do: {:ok, "response"}
end
```

**Reference**: Elixir School - Testing guides

---

## Pattern 8: Tag-Based Test Execution

**Problem**: Run only certain test suites

✅ **Solution**: Use `@tag` attribute

```elixir
defmodule FeatureTest do
  use ExUnit.Case

  @moduletag :feature
  @tag :integration
  @tag slow: true

  @tag :unit
  test "fast unit test", context do
    assert context.value + 1 == 2
  end

  @tag slow: false
  test "slower unit test", context do
    Process.sleep(10)
    assert context.value + 2 == 4
  end
end
```

**Run with**: `mix test --only feature` or `mix test --exclude slow`

**Reference**: Hexdocs ExUnit documentation

---

## Testing Patterns for This File

### Unit Testing
```elixir
test "adds two numbers" do
  assert 1 + 1 == 2
end
```

### Integration Testing
```elixir
test "full request cycle" do
  conn = post(conn, ~p"/api/data", data: %{key: "value"})
  assert response(conn, 201)
  data = json_response(conn, 201)
  assert data["key"] == "value"
end
```

---

## References

**Primary Sources**:
- Elixir School - Testing guides
- Medium - "Break It Before It Breaks You: Advanced Testing Strategies" (Jonny Eberhardt 2025)
- DevTalk - "Ash Framework: How to test changes to resources?" (2025)

**Related Patterns**:
- `genserver.md` - GenServer testing patterns
- `error_handling.md` - Exception testing patterns

**Deep Dives**:
- `skills/exunit-patterns/SKILL.md` - Comprehensive testing guide
