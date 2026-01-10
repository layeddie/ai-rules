# API Evolution Patterns

## Overview

Patterns for evolving APIs while maintaining backward compatibility and minimizing breaking changes.

## Breaking Change Management

### 1. Version Segregation

```elixir
# Separate API versions at the module level
defmodule Api.V1.UsersController do
  use Phoenix.Controller

  def index(conn, params) do
    # V1 implementation with simple structure
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end
end

defmodule Api.V2.UsersController do
  use Phoenix.Controller

  def index(conn, params) do
    # V2 implementation with pagination
    %{page: page, per_page: per_page} = parse_pagination(params)
    users = Accounts.list_users(page: page, per_page: per_page)
    render(conn, :index, users: users)
  end
end
```

### 2. Deprecated Field Strategy

```elixir
# Add new fields, mark old ones as deprecated
defmodule Accounts.UserJSON do
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  def data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      full_name: user.full_name,  # New field
      # @deprecated: Use full_name instead
      first_name: user.first_name,
      # @deprecated: Use full_name instead
      last_name: user.last_name
    }
  end
end
```

## Semantic Versioning Strategies

### 1. MAJOR Version Breaking Changes

```elixir
# MAJOR: Incompatible API changes
# Example: Changing field types
defmodule Api.V1.UserJSON do
  def data(user) do
    %{id: user.id, age: user.age}  # V1: age is integer
  end
end

defmodule Api.V2.UserJSON do
  def data(user) do
    %{id: user.id, birth_date: user.birth_date}  # V2: birth_date is Date
  end
end
```

### 2. MINOR Version Backward-Compatible Additions

```elixir
# MINOR: Add functionality in backward-compatible manner
defmodule Api.V1.UserJSON do
  def data(user) do
    %{id: user.id, name: user.name}
  end
end

defmodule Api.V1_1.UserJSON do  # V1.1 extends V1
  def data(user) do
    base = Api.V1.UserJSON.data(user)
    Map.put(base, :profile_picture, user.profile_url)  # New field
  end
end
```

### 3. PATCH Version Bug Fixes

```elixir
# PATCH: Backward-compatible bug fixes
defmodule Api.V1_0.UserJSON do
  def data(user) do
    %{id: user.id, created_at: user.inserted_at}
  end
end

defmodule Api.V1_1.UserJSON do  # V1.1 fixes timezone bug
  def data(user) do
    %{id: user.id, created_at: DateTime.to_iso8601(user.inserted_at)}
  end
end
```

## Backward Compatibility Patterns

### 1. Field Coexistence

```elixir
defmodule Accounts.UserJSON do
  def data(%User{} = user) do
    %{
      id: user.id,
      # Old field for backward compatibility
      name: user.full_name,
      # New field for new clients
      full_name: user.full_name,
      display_name: user.full_name
    }
  end
end
```

### 2. Default Values for New Fields

```elixir
defmodule Accounts.UserJSON do
  def data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      # New field with default for existing users
      email_verified: Map.get(user, :email_verified, false),
      # New optional field
      profile_image: user.profile_image
    }
  end
end
```

### 3. Response Envelope Pattern

```elixir
# Wrap responses for extensibility
defmodule Api.ResponseWrapper do
  def wrap(data, meta \\ %{}) do
    %{
      data: data,
      meta: %{
        version: "2.0",
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      } |> Map.merge(meta)
    }
  end
end

defmodule Api.V2.UsersController do
  def index(conn, params) do
    users = Accounts.list_users(params)
    json(conn, ResponseWrapper.wrap(users, %{count: length(users)}))
  end
end
```

## Deprecation Workflows

### 1. Sunset Header Pattern

```elixir
# Add deprecation headers to old endpoints
defmodule Api.V1.UsersController do
  plug :add_deprecation_header

  def add_deprecation_header(conn, _opts) do
    put_resp_header(conn, "deprecation", "true")
    |> put_resp_header("sunset", "2026-12-31")
    |> put_resp_header("link", "</api/v2/users>; rel=\"successor-version\"")
  end

  def index(conn, params) do
    users = Accounts.list_users(params)
    render(conn, :index, users: users)
  end
end
```

### 2. Deprecation Warnings in Response

```elixir
defmodule Api.V1.UserJSON do
  def index(%{users: users}) do
    %{
      data: Enum.map(users, &data/1),
      warnings: [
        "This API version is deprecated. Please migrate to v2 by 2026-12-31.",
        "See /api/v2/documentation for migration guide."
      ]
    }
  end
end
```

### 3. Gradual Deprecation Strategy

```elixir
# 3-phase deprecation process
defmodule Api.Deprecation do
  @phase1_date ~D[2026-01-01]  # Announce deprecation
  @phase2_date ~D[2026-06-01]  # Add warnings
  @phase3_date ~D[2026-12-31]  # Remove endpoint

  def deprecation_phase(version) do
    cond do
      Date.after?(Date.utc_today(), @phase3_date) -> :removed
      Date.after?(Date.utc_today(), @phase2_date) -> :warning
      Date.after?(Date.utc_today(), @phase1_date) -> :announced
      true -> :none
    end
  end

  def handle_deprecation(conn, version) do
    case deprecation_phase(version) do
      :none -> conn
      :announced -> put_resp_header(conn, "deprecation", "true")
      :warning ->
        conn
        |> put_resp_header("deprecation", "true")
        |> put_resp_header("sunset", DateTime.to_string(@phase3_date))
      :removed -> send_resp(conn, 410, "API version removed")
    end
  end
end
```

## API Gateway Integration

### 1. Version Routing

```elixir
defmodule ApiRouter do
  use Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", as: :api_v1 do
    pipe_through :api

    resources "/users", Api.V1.UsersController
  end

  scope "/api/v2", as: :api_v2 do
    pipe_through :api

    resources "/users", Api.V2.UsersController
  end
end
```

### 2. Content Negotiation

```elixir
defmodule Api.Negotiation do
  def negotiate_version(conn, _opts) do
    version = extract_version(conn)
    assign(conn, :api_version, version)
  end

  defp extract_version(conn) do
    # Check Accept header for version
    case get_req_header(conn, "accept") do
      ["application/vnd.api+json; version=2"] -> :v2
      ["application/vnd.api+json; version=1"] -> :v1
      _ -> :v1  # Default version
    end
  end
end

defmodule Api.UsersController do
  plug Api.Negotiation

  def index(conn, params) do
    case conn.assigns[:api_version] do
      :v1 -> render_v1_index(conn, params)
      :v2 -> render_v2_index(conn, params)
    end
  end
end
```

### 3. Response Transformation Layer

```elixir
defmodule Api.Transformer do
  @callback transform_v1_to_v2(map()) :: map()
  @callback transform_v2_to_v1(map()) :: map()

  # V1 to V2 transformation
  def transform_v1_to_v2(data) do
    data
    |> Map.update(:users, [], &transform_users_v1_to_v2/1)
  end

  defp transform_users_v1_to_v2(users) do
    Enum.map(users, fn user ->
      %{
        id: user.id,
        emailAddress: user.email,  # Renamed field
        fullName: user.first_name <> " " <> user.last_name,  # Combined
        metadata: %{
          createdAt: user.created_at,
          updatedAt: user.updated_at
        }
      }
    end)
  end
end
```

## Migration Guide Pattern

### 1. Diff Documentation

```elixir
# API version diff documentation
defmodule Api.V2.MigrationGuide do
  @moduledoc """
  V1 to V2 Migration Guide

  ## Breaking Changes

  ### User Resource
  - `email` → `emailAddress` (renamed)
  - `first_name`, `last_name` → `fullName` (combined)
  - `created_at`, `updated_at` → `metadata.createdAt`, `metadata.updatedAt`

  ## New Features

  - Added pagination support
  - Added filtering capabilities
  - Added field expansion with `?fields=id,emailAddress`

  ## Deprecated Features

  - Legacy date format (ISO 8601 required)
  - XML support (JSON only)

  ## Migration Timeline

  - 2026-01-01: V2 available
  - 2026-06-01: V1 deprecation warnings begin
  - 2026-12-31: V1 sunset
  """

  @breaking_changes [
    %{field: "email", new_field: "emailAddress", type: :rename},
    %{field: "first_name,last_name", new_field: "fullName", type: :combine}
  ]

  def breaking_changes, do: @breaking_changes
end
```

## Related Skills

- [API Design](../api-design/SKILL.md) - Design principles for new APIs
- [API Versioning](../api-versioning/SKILL.md) - Comprehensive versioning strategies

## Related Patterns

- [Phoenix Controllers](../phoenix_controllers.md) - Controller best practices
- [Circuit Breaker](../circuit_breaker.md) - Protect APIs from cascading failures
