# Phoenix Controller Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: Phoenix documentation + Thoughtbot (Context patterns) (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Building Phoenix controllers for web APIs
- Implementing authentication and authorization
- Handling errors and redirects
- Delegating business logic to contexts

❌ **DON'T use this file when**:
- Building business logic in controllers (use contexts instead)
- Using raw SQL queries (use Ecto/Ash)
- Implementing complex state management in controllers

**See also**:
- `liveview.md` - Phoenix LiveView patterns
- `ash_resources.md` - Ash resource patterns
- `error_handling.md` - Error handling patterns

---

## Pattern 1: Thin Controllers with Context Delegation

**Problem**: Controllers become bloated with business logic

✅ **Solution**: Delegate to contexts

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  action :index do
    # Thin controller - just calls context
    MyApp.Accounts.list_users()
    render(conn, :index, users: MyApp.Accounts.list_users())
  end

  action :show do
    with {:ok, user} <- MyApp.Accounts.get_user(id),
         {:ok, posts} <- MyApp.Blog.list_user_posts(id) do
      render(conn, :show, user: user, posts: posts)
    else
      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> put_view(MyAppWeb.ErrorView, "404.html")
    end
  end
end
```

**Reference**: Thoughtbot - "Understanding LiveView's Core Principles" (2025)

---

## Pattern 2: Error Handling with put_flash

**Problem**: Displaying errors to users properly

✅ **Solution**: Use `put_flash` for feedback

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  action :create do
    case MyApp.Accounts.create_user(params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully")
        |> redirect(to: ~p"/users/#{user.id}")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Failed to create user")
        |> put_view(MyAppWeb.ErrorView, :errors, changeset)
        |> render(:new, changeset: changeset)
    end
  end
end
```

**Reference**: `error_handling.md` - Tuple patterns and exceptions

---

## Pattern 3: Authentication and Authorization in Controllers

**Problem**: Checking auth for every action

✅ **Solution**: Use plug pipeline or action helpers

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  # Option 1: Use plug for entire controller
  plug MyAppWeb.Plugs.RequireAuth

  # Option 2: Use action helper for specific actions
  action :profile do
    assign(conn, :current_user, Guardian.Plug.current_resource(conn))
  end
end

defmodule MyAppWeb.Plugs.RequireAuth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      nil -> 
        conn
        |> put_status(401)
        |> halt()

      _resource -> 
        assign(conn, :current_user, resource)
    end
  end
end
```

**Reference**: Thoughtbot - "Lessons From Using Phoenix 1.3"

---

## Pattern 4: JSON vs HTML Responses

**Problem**: Different content types for different clients

✅ **Solution**: Check content type or use pattern matching

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  action :index do
    posts = MyApp.Blog.list_posts()
    # HTML response (default)
    render(conn, :index, posts: posts)
  end

  def show(conn, %{"id" => id}) do
    case get_format(conn) do
      "html" -> render(conn, :show, post: MyApp.Blog.get_post!(id))
      "json" -> json(conn, post: MyApp.Blog.get_post!(id))
    end
  end
end
```

**Reference**: Phoenix documentation

---

## Pattern 5: File Uploads in Controllers

**Problem**: Handling multipart form uploads

✅ **Solution**: Use Plug.Parsers and file handling

```elixir
defmodule MyAppWeb.UploadController do
  use MyAppWeb, :controller

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart],
    pass: ["image/*"]

  action :create do
    case MyFileStorage.save(conn.body_params, conn.req_headers) do
      {:ok, file} ->
        conn
        |> put_status(201)
        |> json(%{id: file.id, url: file.url})

      {:error, reason} ->
        conn
        |> put_status(422)
        |> json(%{error: reason})
    end
  end
end
```

**Reference**: Phoenix documentation

---

## Pattern 6: Pagination and Filtering

**Problem**: Large result sets

✅ **Solution**: Use Ecto/Ash for database operations

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  def index(conn, params) do
    # Option 1: Use Ecto paginate
    page = MyApp.Repo.paginate(MyApp.User, params)

    # Option 2: Use Ash Query (for Ash)
    Ash.Query.for_read(MyApp.User)
    |> Ash.Query.limit(params["per_page"] || 10)
    |> Ash.Query.offset(params["page"] || 0)
    |> MyApp.Accounts.read()

    render(conn, :index, page: page)
  end
end
```

**Reference**: `ash_resources.md` - Ash resource patterns

---

## Pattern 7: Strong Etag Parameters

**Problem**: Malicious URL manipulation

✅ **Solution**: Use proper Ecto schemas

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  alias MyApp.Blog

  action :show(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    render(conn, :show, post: post, layout: false)
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    # Strong Etag
    etag = Base.encode16(:crypto.hash(:md4, post.updated_at))
    conn
    |> put_resp_header("etag", etag)
    |> render(conn, :show, post: post)
  end
end
```

**Reference**: Phoenix documentation

---

## Pattern 8: Streaming Responses

**Problem**: Large datasets exhaust memory

✅ **Solution**: Use stream responses

```elixir
defmodule MyAppWeb.ExportController do
  use MyAppWeb, :controller

  def export(conn, _params) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=export.csv")
    |> send_chunk("header1,header2,header3\n")
    |> send_chunk("data1,data2,data3\n")
    |> send_chunk("data4,data5,data6\n")
    |> send_chunk("data7,data8,data9\n")
  end
end
```

**Reference**: Phoenix documentation

---

## Pattern 9: CORS Handling

**Problem**: Cross-origin requests for APIs

✅ **Solution**: Use CORS plug

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :api do
    plug CORSPlug,
    plug :accepts, ["json"]

    scope "/api", MyAppWeb do
      pipe_through :api

      get "/users", MyAppWeb.UserController, :index
      post "/users", MyAppWeb.UserController, :create
    end
  end
end
```

**Reference**: Phoenix CORS documentation

---

## Testing Patterns for This File

### Unit Testing Controllers

```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase

  test "index renders users", %{conn: conn} do
    conn = get(conn, ~p"/users")
    assert html_response(conn, 200) =~ "Users"
  end

  test "create redirects on success", %{conn: conn} do
    conn = post(conn, ~p"/users", user: %{name: "Test"})
    assert redirected_to(conn, ~p"/users/test-user")
    assert get_flash(conn, :info) =~ "created successfully"
  end
end
```

### Integration Testing

```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase

  test "full user lifecycle", %{conn: conn} do
    # Create
    conn = post(conn, ~p"/api/users", user: %{name: "Test User", email: "test@example.com"})
    assert response(conn, 201)

    # Read
    conn = get(conn, "/api/users/#{user_id}")
    assert json_response(conn, 200)

    # Update
    conn = patch(conn, "/api/users/#{user_id}", user: %{name: "Updated User"})
    assert response(conn, 200)

    # Delete
    conn = delete(conn, "/api/users/#{user_id}")
    assert response(conn, 204)
  end
end
```

---

## References

**Primary Sources**:
- Thoughtbot - "Lessons From Using Phoenix 1.3"
- Phoenix Framework documentation

**Related Patterns**:
- `liveview.md` - Phoenix LiveView patterns
- `ash_resources.md` - Ash resource patterns
- `error_handling.md` - Error handling patterns
