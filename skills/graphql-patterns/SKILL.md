---
name: graphql-patterns
description: GraphQL patterns with Absinthe framework for Elixir/Phoenix applications
---

# GraphQL Patterns Skill

Use this skill when implementing GraphQL APIs with Absinthe in Elixir/Phoenix applications.

## When to Use

- Designing GraphQL schemas
- Implementing resolvers and mutations
- Setting up GraphQL subscriptions
- Optimizing GraphQL queries
- Handling authentication and authorization
- Testing GraphQL APIs

## Overview

Absinthe is the de-facto GraphQL implementation for Elixir. It provides:
- Type-safe schema definition
- Query complexity analysis
- Real-time subscriptions
- Integration with Phoenix and Ecto
- Comprehensive middleware support

## Schema Definition

### Basic Types

```elixir
# lib/my_app_web/schema.ex
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  import_types MyAppWeb.Schema.Types

  query do
    field :users, list_of(:user) do
      resolve &MyAppWeb.Resolvers.User.list_users/3
    end

    field :user, :user do
      arg :id, non_null(:id)
      resolve &MyAppWeb.Resolvers.User.get_user/3
    end
  end

  mutation do
    field :create_user, :user do
      arg :email, non_null(:string)
      arg :name, non_null(:string)
      resolve &MyAppWeb.Resolvers.User.create_user/3
    end
  end

  subscription do
    field :user_created, :user do
      config fn _args, _info ->
        {:ok, topic: "users"}
      end
    end
  end
end
```

### Custom Types

```elixir
# lib/my_app_web/schema/types.ex
defmodule MyAppWeb.Schema.Types do
  use Absinthe.Schema.Notation

  object :user do
    field :id, :id
    field :email, :string
    field :name, :string
    field :posts, list_of(:post) do
      resolve &MyAppWeb.Resolvers.Post.list_posts/3
    end
    field :inserted_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  object :post do
    field :id, :id
    field :title, :string
    field :body, :string
    field :author, :user do
      resolve &MyAppWeb.Resolvers.User.get_user/3
    end
  end

  input_object :user_input do
    field :email, non_null(:string)
    field :name, non_null(:string)
  end

  enum :post_status do
    value :draft
    value :published
    value :archived
  end

  scalar :naive_datetime do
    parse &Absinthe.Type.Custom.NaiveDateTime.parse/1
    serialize &Absinthe.Type.Custom.NaiveDateTime.serialize/1
  end
end
```

## Resolvers

### Basic Resolvers

```elixir
# lib/my_app_web/resolvers/user.ex
defmodule MyAppWeb.Resolvers.User do
  def list_users(_parent, _args, _resolution) do
    {:ok, MyApp.Accounts.list_users()}
  end

  def get_user(_parent, %{id: id}, _resolution) do
    case MyApp.Accounts.get_user(id) do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end

  def create_user(_parent, args, _resolution) do
    case MyApp.Accounts.create_user(args) do
      {:ok, user} ->
        # Publish subscription event
        Absinthe.Subscription.publish(
          MyAppWeb.Endpoint,
          user,
          user_created: "users"
        )
        {:ok, user}

      {:error, changeset} ->
        {:error, format_changeset_errors(changeset)}
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
```

### Batch Loading with Dataloader

```elixir
# lib/my_app_web/schema.ex
defmodule MyAppWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

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

  query do
    field :users, list_of(:user) do
      resolve dataloader(MyApp.Accounts)
    end
  end
end

# lib/my_app/accounts.ex
defmodule MyApp.Accounts do
  use Dataloader

  def data do
    Dataloader.Ecto.new(MyApp.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end
end
```

## Mutations

### CRUD Operations

```elixir
# lib/my_app_web/schema.ex
mutation do
  field :create_post, :post do
    arg :title, non_null(:string)
    arg :body, non_null(:string)
    arg :status, :post_status, default_value: :draft

    resolve &MyAppWeb.Resolvers.Post.create_post/3
  end

  field :update_post, :post do
    arg :id, non_null(:id)
    arg :title, :string
    arg :body, :string
    arg :status, :post_status

    resolve &MyAppWeb.Resolvers.Post.update_post/3
  end

  field :delete_post, :post do
    arg :id, non_null(:id)

    resolve &MyAppWeb.Resolvers.Post.delete_post/3
  end
end

# lib/my_app_web/resolvers/post.ex
defmodule MyAppWeb.Resolvers.Post do
  def create_post(_parent, args, %{context: %{current_user: user}}) do
    attrs = Map.put(args, :author_id, user.id)
    MyApp.Content.create_post(attrs)
  end

  def update_post(_parent, %{id: id} = args, %{context: %{current_user: user}}) do
    case MyApp.Content.get_post(id) do
      nil ->
        {:error, "Post not found"}

      post ->
        if post.author_id == user.id do
          MyApp.Content.update_post(post, args)
        else
          {:error, "Unauthorized"}
        end
    end
  end

  def delete_post(_parent, %{id: id}, %{context: %{current_user: user}}) do
    case MyApp.Content.get_post(id) do
      nil ->
        {:error, "Post not found"}

      post ->
        if post.author_id == user.id do
          MyApp.Content.delete_post(post)
        else
          {:error, "Unauthorized"}
        end
    end
  end
end
```

## Authentication & Authorization

### Middleware

```elixir
# lib/my_app_web/middleware/auth.ex
defmodule MyAppWeb.Middleware.Auth do
  @behaviour Absinthe.Middleware

  def call(resolution, :authenticated) do
    case resolution.context do
      %{current_user: _} ->
        resolution

      _ ->
        Absinthe.Resolution.put_result(resolution, {:error, "Not authenticated"})
    end
  end

  def call(resolution, {:role, role}) do
    case resolution.context do
      %{current_user: %{role: ^role}} ->
        resolution

      %{current_user: _} ->
        Absinthe.Resolution.put_result(resolution, {:error, "Unauthorized"})

      _ ->
        Absinthe.Resolution.put_result(resolution, {:error, "Not authenticated"})
    end
  end
end

# Usage in schema
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  middleware fn resolution, _field ->
    MyAppWeb.Middleware.Auth.call(resolution, :authenticated)
  end

  # Apply to specific fields
  object :protected_queries do
    field :my_posts, list_of(:post) do
      middleware MyAppWeb.Middleware.Auth, :authenticated
      resolve &MyAppWeb.Resolvers.Post.my_posts/3
    end
  end
end
```

### Context Setup

```elixir
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
        case verify_token(token) do
          {:ok, user} -> %{current_user: user}
          _ -> %{}
        end

      _ ->
        %{}
    end
  end

  defp verify_token(token) do
    MyApp.Guardian.resource_from_token(token)
  end
end

# Router
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

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: MyAppWeb.Schema,
      interface: :simple
  end
end
```

## Subscriptions

### Real-Time Updates

```elixir
# lib/my_app_web/schema.ex
subscription do
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

# lib/my_app_web/resolvers/post.ex
def create_post(_parent, args, %{context: %{current_user: user}}) do
  attrs = Map.put(args, :author_id, user.id)

  case MyApp.Content.create_post(attrs) do
    {:ok, post} ->
      # Publish to subscription
      Absinthe.Subscription.publish(
        MyAppWeb.Endpoint,
        post,
        [post_created: "*", post_created: user.id]
      )

      {:ok, post}

    error ->
      error
  end
end

# lib/my_app_web/resolvers/comment.ex
def add_comment(_parent, args, %{context: %{current_user: user}}) do
  attrs = Map.merge(args, %{author_id: user.id})

  case MyApp.Content.create_comment(attrs) do
    {:ok, comment} ->
      Absinthe.Subscription.publish(
        MyAppWeb.Endpoint,
        comment,
        comment_added: args.post_id
      )

      {:ok, comment}

    error ->
      error
  end
end
```

### Frontend Subscription Setup

```javascript
// JavaScript client example using Apollo
import { ApolloClient, InMemoryCache, split } from '@apollo/client'
import { WebSocketLink } from '@apollo/client/link/ws'
import { getMainDefinition } from '@apollo/client/utilities'

const wsLink = new WebSocketLink({
  uri: 'ws://localhost:4000/socket',
  options: {
    reconnect: true
  }
})

const splitLink = split(
  ({ query }) => {
    const definition = getMainDefinition(query)
    return (
      definition.kind === 'OperationDefinition' &&
      definition.operation === 'subscription'
    )
  },
  wsLink,
  httpLink
)

const client = new ApolloClient({
  link: splitLink,
  cache: new InMemoryCache()
})
```

## Performance Optimization

### Query Complexity Analysis

```elixir
# lib/my_app_web/schema.ex
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  # Configure complexity limits
  def middleware(middleware, field, object) do
    middleware
    |> Absinthe.Middleware.Complexity.add_complexity(field, object)
  end

  # Custom complexity calculation
  object :user do
    field :posts, list_of(:post) do
      complexity fn child_complexity, _args, _info ->
        10 + child_complexity * 5
      end

      resolve &MyAppWeb.Resolvers.Post.list_posts/3
    end
  end

  # Set max complexity
  query do
    field :complex_query, :string do
      complexity 1000
      resolve fn _, _, _ -> {:ok, "complex"} end
    end
  end
end

# config/config.exs
config :my_app, MyAppWeb.Schema,
  max_complexity: 200
```

### N+1 Prevention

```elixir
# Use dataloader for associations
defmodule MyAppWeb.Schema do
  use Absinthe.Schema
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :user do
    field :posts, list_of(:post) do
      # Automatically batches queries
      resolve dataloader(MyApp.Content)
    end
  end
end

# Or manual batching
defmodule MyAppWeb.Resolvers.Post do
  def list_posts(%User{id: user_id}, _args, _resolution) do
    {:ok, MyApp.Content.list_posts_for_user(user_id)}
  end

  # Batch resolver for multiple users
  def batch_list_posts(users, _args, _resolution) do
    user_ids = Enum.map(users, & &1.id)
    posts = MyApp.Content.list_posts_for_users(user_ids)
    grouped = Enum.group_by(posts, & &1.author_id)

    {:ok, Enum.map(users, fn user ->
      Map.get(grouped, user.id, [])
    end)}
  end
end
```

## Testing

### Query Testing

```elixir
# test/my_app_web/schema_test.exs
defmodule MyAppWeb.SchemaTest do
  use MyAppWeb.ConnCase

  describe "users query" do
    test "returns list of users", %{conn: conn} do
      user = insert(:user)

      query = """
      {
        users {
          id
          email
          name
        }
      }
      """

      conn =
        conn
        |> post("/api/graphql", %{query: query})

      response = json_response(conn, 200)

      assert response["data"]["users"] == [
               %{
                 "id" => to_string(user.id),
                 "email" => user.email,
                 "name" => user.name
               }
             ]
    end
  end

  describe "createUser mutation" do
    test "creates a new user", %{conn: conn} do
      mutation = """
      mutation CreateUser($email: String!, $name: String!) {
        createUser(email: $email, name: $name) {
          id
          email
          name
        }
      }
      """

      variables = %{
        email: "test@example.com",
        name: "Test User"
      }

      conn =
        conn
        |> post("/api/graphql", %{query: mutation, variables: variables})

      response = json_response(conn, 200)

      assert response["data"]["createUser"]["email"] == "test@example.com"
      assert response["data"]["createUser"]["name"] == "Test User"
    end
  end
end
```

### Subscription Testing

```elixir
# test/my_app_web/subscription_test.exs
defmodule MyAppWeb.SubscriptionTest do
  use MyAppWeb.ChannelCase

  describe "postCreated subscription" do
    test "notifies when post is created" do
      # Start subscription
      subscription = """
      subscription {
        postCreated {
          id
          title
        }
      }
      """

      # Connect to socket
      {:ok, _, socket} = socket(MyAppWeb.UserSocket, "user_id", %{})
      |> subscribe_and_join(Absinthe.GraphqlWS, "__absinthe__:control")

      # Trigger subscription
      {:ok, post} = MyApp.Content.create_post(%{
        title: "Test Post",
        body: "Body",
        author_id: 1
      })

      # Assert notification received
      assert_push "subscription:data", %{result: result}
      assert result["data"]["postCreated"]["title"] == "Test Post"
    end
  end
end
```

## Best Practices

### Schema Organization

```elixir
# Split schema into modules
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  import_types MyAppWeb.Schema.Types
  import_types MyAppWeb.Schema.Queries.User
  import_types MyAppWeb.Schema.Queries.Post
  import_types MyAppWeb.Schema.Mutations.User
  import_types MyAppWeb.Schema.Mutations.Post

  query do
    import_fields :user_queries
    import_fields :post_queries
  end

  mutation do
    import_fields :user_mutations
    import_fields :post_mutations
  end
end

# lib/my_app_web/schema/queries/user.ex
defmodule MyAppWeb.Schema.Queries.User do
  use Absinthe.Schema.Notation

  object :user_queries do
    field :users, list_of(:user) do
      resolve &MyAppWeb.Resolvers.User.list_users/3
    end
  end
end
```

### Error Handling

```elixir
# Custom error formatting
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  def plugins do
    [Absinthe.Middleware.MapGetError] ++ Absinthe.Plugin.defaults()
  end
end

# Resolver error handling
defmodule MyAppWeb.Resolvers.User do
  def create_user(_parent, args, _resolution) do
    case MyApp.Accounts.create_user(args) do
      {:ok, user} ->
        {:ok, user}

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)
        {:error, %{message: "Validation failed", details: errors}}
    end
  end
end
```

### Documentation

```elixir
# Add documentation to schema
object :user do
  @desc "User object representing a registered user"
  field :id, :id, description: "Unique identifier"
  field :email, :string, description: "User's email address"
  field :name, :string, description: "User's display name"

  field :posts, list_of(:post), description: "Posts created by this user" do
    resolve &MyAppWeb.Resolvers.Post.list_posts/3
  end
end
```

## Related Skills

- **api-design**: REST vs GraphQL decision making
- **liveview-patterns**: Real-time UI patterns
- **security-patterns**: GraphQL security best practices
- **testing**: Testing strategies for GraphQL APIs
