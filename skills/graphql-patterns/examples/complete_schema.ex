# Complete GraphQL/Absinthe Example

## Full Schema with Authentication

```elixir
# lib/my_app_web/schema.ex
defmodule MyAppWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  import_types Absinthe.Type.Custom
  import_types MyAppWeb.Schema.Types
  import_types MyAppWeb.Schema.Enums
  import_types MyAppWeb.Schema.Inputs

  import Absinthe.Resolution.Helpers, only: [dataloader: 1, dataloader: 2]

  # Dataloader configuration
  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(MyApp.Accounts, MyApp.Accounts.data())
      |> Dataloader.add_source(MyApp.Content, MyApp.Content.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  # Global middleware for authentication
  middleware fn resolution, _field ->
    case resolution.context do
      %{current_user: _} -> resolution
      _ -> resolution
    end
  end

  query do
    @desc "Get currently authenticated user"
    field :me, :user do
      middleware MyAppWeb.Middleware.Auth, :authenticated
      resolve fn _, _, %{context: %{current_user: user}} ->
        {:ok, user}
      end
    end

    @desc "Get list of users"
    field :users, list_of(:user) do
      arg :limit, :integer, default_value: 20
      arg :offset, :integer, default_value: 0
      middleware MyAppWeb.Middleware.Auth, :authenticated
      resolve &MyAppWeb.Resolvers.User.list_users/3
    end

    @desc "Get single user by ID"
    field :user, :user do
      arg :id, non_null(:id)
      resolve dataloader(MyApp.Accounts, :user)
    end

    @desc "Get list of posts"
    field :posts, list_of(:post) do
      arg :status, :post_status
      arg :limit, :integer, default_value: 20
      arg :order, :sort_order, default_value: :desc
      resolve &MyAppWeb.Resolvers.Post.list_posts/3
    end

    @desc "Get single post by ID"
    field :post, :post do
      arg :id, non_null(:id)
      resolve dataloader(MyApp.Content, :post)
    end
  end

  mutation do
    @desc "Create new user"
    field :create_user, :user do
      arg :input, non_null(:user_input)
      resolve &MyAppWeb.Resolvers.User.create_user/3
    end

    @desc "Update user profile"
    field :update_user, :user do
      arg :id, non_null(:id)
      arg :input, non_null(:user_update_input)
      middleware MyAppWeb.Middleware.Auth, :authenticated
      resolve &MyAppWeb.Resolvers.User.update_user/3
    end

    @desc "Delete user account"
    field :delete_user, :user do
      arg :id, non_null(:id)
      middleware MyAppWeb.Middleware.Auth, {:role, :admin}
      resolve &MyAppWeb.Resolvers.User.delete_user/3
    end

    @desc "Create new post"
    field :create_post, :post do
      arg :input, non_null(:post_input)
      middleware MyAppWeb.Middleware.Auth, :authenticated
      resolve &MyAppWeb.Resolvers.Post.create_post/3
    end

    @desc "Update post"
    field :update_post, :post do
      arg :id, non_null(:id)
      arg :input, non_null(:post_update_input)
      middleware MyAppWeb.Middleware.Auth, :authenticated
      resolve &MyAppWeb.Resolvers.Post.update_post/3
    end

    @desc "Delete post"
    field :delete_post, :post do
      arg :id, non_null(:id)
      middleware MyAppWeb.Middleware.Auth, :authenticated
      resolve &MyAppWeb.Resolvers.Post.delete_post/3
    end
  end

  subscription do
    @desc "Subscribe to new posts"
    field :post_created, :post do
      arg :author_id, :id

      config fn args, _info ->
        case args do
          %{author_id: author_id} ->
            {:ok, topic: author_id}
          _ ->
            {:ok, topic: "*"}
        end
      end
    end

    @desc "Subscribe to post updates"
    field :post_updated, :post do
      arg :post_id, non_null(:id)

      config fn %{post_id: post_id}, _info ->
        {:ok, topic: post_id}
      end
    end

    @desc "Subscribe to new comments"
    field :comment_added, :comment do
      arg :post_id, non_null(:id)

      config fn %{post_id: post_id}, _info ->
        {:ok, topic: post_id}
      end

      resolve fn comment, _, _ ->
        {:ok, comment}
      end
    end
  end
end
```

## Types and Enums

```elixir
# lib/my_app_web/schema/types.ex
defmodule MyAppWeb.Schema.Types do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :user do
    field :id, :id
    field :email, :string
    field :name, :string
    field :role, :user_role
    field :bio, :string
    field :avatar_url, :string

    field :posts, list_of(:post) do
      arg :limit, :integer, default_value: 10
      resolve dataloader(MyApp.Content)
    end

    field :posts_count, :integer do
      resolve fn user, _, _ ->
        {:ok, MyApp.Content.count_posts_for_user(user.id)}
      end
    end

    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  object :post do
    field :id, :id
    field :title, :string
    field :body, :string
    field :excerpt, :string do
      resolve fn post, _, _ ->
        {:ok, String.slice(post.body, 0..200)}
      end
    end
    field :status, :post_status
    field :view_count, :integer

    field :author, :user do
      resolve dataloader(MyApp.Accounts)
    end

    field :comments, list_of(:comment) do
      arg :limit, :integer, default_value: 20
      resolve dataloader(MyApp.Content)
    end

    field :comments_count, :integer do
      resolve fn post, _, _ ->
        {:ok, MyApp.Content.count_comments_for_post(post.id)}
      end
    end

    field :tags, list_of(:tag) do
      resolve dataloader(MyApp.Content)
    end

    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  object :comment do
    field :id, :id
    field :body, :string

    field :author, :user do
      resolve dataloader(MyApp.Accounts)
    end

    field :post, :post do
      resolve dataloader(MyApp.Content)
    end

    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  object :tag do
    field :id, :id
    field :name, :string
    field :slug, :string

    field :posts_count, :integer do
      resolve fn tag, _, _ ->
        {:ok, MyApp.Content.count_posts_for_tag(tag.id)}
      end
    end
  end
end

# lib/my_app_web/schema/enums.ex
defmodule MyAppWeb.Schema.Enums do
  use Absinthe.Schema.Notation

  enum :user_role do
    value :admin, description: "Administrator with full access"
    value :moderator, description: "Moderator with limited admin access"
    value :user, description: "Regular user"
  end

  enum :post_status do
    value :draft, description: "Draft post, not published"
    value :published, description: "Published post, visible to all"
    value :archived, description: "Archived post, not visible"
  end

  enum :sort_order do
    value :asc
    value :desc
  end
end
```

## Input Objects

```elixir
# lib/my_app_web/schema/inputs.ex
defmodule MyAppWeb.Schema.Inputs do
  use Absinthe.Schema.Notation

  input_object :user_input do
    field :email, non_null(:string)
    field :name, non_null(:string)
    field :password, non_null(:string)
    field :bio, :string
  end

  input_object :user_update_input do
    field :name, :string
    field :bio, :string
    field :avatar_url, :string
  end

  input_object :post_input do
    field :title, non_null(:string)
    field :body, non_null(:string)
    field :status, :post_status, default_value: :draft
    field :tag_ids, list_of(:id)
  end

  input_object :post_update_input do
    field :title, :string
    field :body, :string
    field :status, :post_status
    field :tag_ids, list_of(:id)
  end

  input_object :comment_input do
    field :post_id, non_null(:id)
    field :body, non_null(:string)
  end
end
```

## Complete Resolvers

```elixir
# lib/my_app_web/resolvers/user.ex
defmodule MyAppWeb.Resolvers.User do
  alias MyApp.Accounts

  def list_users(_parent, %{limit: limit, offset: offset}, _resolution) do
    {:ok, Accounts.list_users(limit: limit, offset: offset)}
  end

  def get_user(_parent, %{id: id}, _resolution) do
    case Accounts.get_user(id) do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end

  def create_user(_parent, %{input: input}, _resolution) do
    case Accounts.register_user(input) do
      {:ok, user} ->
        {:ok, user}

      {:error, changeset} ->
        {:error, format_errors(changeset)}
    end
  end

  def update_user(_parent, %{id: id, input: input}, %{context: %{current_user: current_user}}) do
    if can_update_user?(current_user, id) do
      case Accounts.get_user(id) do
        nil ->
          {:error, "User not found"}

        user ->
          case Accounts.update_user(user, input) do
            {:ok, user} -> {:ok, user}
            {:error, changeset} -> {:error, format_errors(changeset)}
          end
      end
    else
      {:error, "Unauthorized"}
    end
  end

  def delete_user(_parent, %{id: id}, _resolution) do
    case Accounts.get_user(id) do
      nil ->
        {:error, "User not found"}

      user ->
        case Accounts.delete_user(user) do
          {:ok, user} -> {:ok, user}
          {:error, changeset} -> {:error, format_errors(changeset)}
        end
    end
  end

  defp can_update_user?(%{role: :admin}, _user_id), do: true
  defp can_update_user?(%{id: user_id}, user_id), do: true
  defp can_update_user?(_, _), do: false

  defp format_errors(changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)

    %{message: "Validation failed", details: errors}
  end
end

# lib/my_app_web/resolvers/post.ex
defmodule MyAppWeb.Resolvers.Post do
  alias MyApp.Content

  def list_posts(_parent, args, _resolution) do
    {:ok, Content.list_posts(args)}
  end

  def create_post(_parent, %{input: input}, %{context: %{current_user: user}}) do
    attrs = Map.put(input, :author_id, user.id)

    case Content.create_post(attrs) do
      {:ok, post} ->
        # Publish to subscriptions
        Absinthe.Subscription.publish(
          MyAppWeb.Endpoint,
          post,
          [
            post_created: "*",
            post_created: user.id
          ]
        )

        {:ok, post}

      {:error, changeset} ->
        {:error, format_errors(changeset)}
    end
  end

  def update_post(_parent, %{id: id, input: input}, %{context: %{current_user: user}}) do
    case Content.get_post(id) do
      nil ->
        {:error, "Post not found"}

      post ->
        if can_edit_post?(user, post) do
          case Content.update_post(post, input) do
            {:ok, updated_post} ->
              # Publish to subscription
              Absinthe.Subscription.publish(
                MyAppWeb.Endpoint,
                updated_post,
                post_updated: post.id
              )

              {:ok, updated_post}

            {:error, changeset} ->
              {:error, format_errors(changeset)}
          end
        else
          {:error, "Unauthorized"}
        end
    end
  end

  def delete_post(_parent, %{id: id}, %{context: %{current_user: user}}) do
    case Content.get_post(id) do
      nil ->
        {:error, "Post not found"}

      post ->
        if can_edit_post?(user, post) do
          case Content.delete_post(post) do
            {:ok, deleted_post} -> {:ok, deleted_post}
            {:error, changeset} -> {:error, format_errors(changeset)}
          end
        else
          {:error, "Unauthorized"}
        end
    end
  end

  defp can_edit_post?(%{role: :admin}, _post), do: true
  defp can_edit_post?(%{id: author_id}, %{author_id: author_id}), do: true
  defp can_edit_post?(_, _), do: false

  defp format_errors(changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)

    %{message: "Validation failed", details: errors}
  end
end
```

## Middleware Implementation

```elixir
# lib/my_app_web/middleware/auth.ex
defmodule MyAppWeb.Middleware.Auth do
  @behaviour Absinthe.Middleware

  def call(resolution, :authenticated) do
    case resolution.context do
      %{current_user: _} -> resolution
      _ -> Absinthe.Resolution.put_result(resolution, {:error, "Not authenticated"})
    end
  end

  def call(resolution, {:role, required_role}) do
    case resolution.context do
      %{current_user: %{role: role}} when role == required_role ->
        resolution

      %{current_user: _} ->
        Absinthe.Resolution.put_result(resolution, {:error, "Unauthorized"})

      _ ->
        Absinthe.Resolution.put_result(resolution, {:error, "Not authenticated"})
    end
  end

  def call(resolution, {:belongs_to, field}) do
    with %{current_user: user} <- resolution.context,
         parent <- resolution.source,
         true <- can_access?(user, parent, field) do
      resolution
    else
      _ ->
        Absinthe.Resolution.put_result(resolution, {:error, "Unauthorized"})
    end
  end

  defp can_access?(user, resource, field) do
    resource_user_id = Map.get(resource, field)
    user.id == resource_user_id or user.role == :admin
  end
end
```

## Phoenix Integration

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug MyAppWeb.Plugs.GraphQLContext
  end

  scope "/api" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug,
      schema: MyAppWeb.Schema

    if Mix.env() == :dev do
      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: MyAppWeb.Schema,
        interface: :simple,
        default_query: """
        {
          users {
            id
            email
            name
          }
        }
        """
    end
  end

  # WebSocket endpoint for subscriptions
  scope "/socket" do
    pipe_through :api
    get "/websocket", MyAppWeb.GraphQLWebSocket, :websocket
  end
end

# lib/my_app_web/plugs/graphql_context.ex
defmodule MyAppWeb.Plugs.GraphQLContext do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case MyApp.Guardian.resource_from_token(token) do
          {:ok, user, _claims} -> %{current_user: user}
          {:error, _} -> %{}
        end

      _ ->
        %{}
    end
  end
end
```

## Complete Test Examples

```elixir
# test/my_app_web/schema_test.exs
defmodule MyAppWeb.SchemaTest do
  use MyAppWeb.ConnCase

  describe "users query" do
    test "returns list of users when authenticated", %{conn: conn} do
      user = insert(:user, role: :admin)
      token = generate_token(user)

      query = """
      {
        users {
          id
          email
          name
          role
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/graphql", %{query: query})

      response = json_response(conn, 200)

      assert length(response["data"]["users"]) == 1
      assert hd(response["data"]["users"])["email"] == user.email
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      {
        users {
          id
          email
        }
      }
      """

      conn = post(conn, "/api/graphql", %{query: query})
      response = json_response(conn, 200)

      assert response["errors"] != nil
      assert hd(response["errors"])["message"] =~ "Not authenticated"
    end
  end

  describe "createUser mutation" do
    test "creates a new user", %{conn: conn} do
      mutation = """
      mutation CreateUser($input: UserInput!) {
        createUser(input: $input) {
          id
          email
          name
          role
        }
      }
      """

      variables = %{
        input: %{
          email: "test@example.com",
          name: "Test User",
          password: "SecurePassword123"
        }
      }

      conn = post(conn, "/api/graphql", %{query: mutation, variables: variables})
      response = json_response(conn, 200)

      assert response["data"]["createUser"]["email"] == "test@example.com"
      assert response["data"]["createUser"]["name"] == "Test User"
      assert response["data"]["createUser"]["role"] == "USER"
    end
  end

  describe "postCreated subscription" do
    test "receives notification when post is created" do
      query = """
      subscription {
        postCreated {
          id
          title
          body
        }
      }
      """

      # Subscribe to WebSocket
      {:ok, socket} = Phoenix.ChannelTest.connect(MyAppWeb.UserSocket, %{})
      {:ok, _, socket} = subscribe_and_join(socket, Absinthe.GraphqlWS, "__absinthe__:control")

      # Reference the subscription
      ref = push(socket, "doc", %{query: query})

      # Create a post
      {:ok, post} = MyApp.Content.create_post(%{
        title: "Test Post",
        body: "Body content",
        author_id: 1
      })

      # Assert subscription notification
      assert_reply ref, :ok, %{subscriptionId: subscription_id}
      assert_push "subscription:data", %{result: result, subscriptionId: ^subscription_id}
      assert result["data"]["postCreated"]["title"] == "Test Post"
    end
  end
end
```
