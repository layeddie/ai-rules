# Channels Patterns

## Overview

Patterns for implementing Phoenix Channels for real-time, bidirectional communication.

## Channel Authorization

### Token-Based Authorization

```elixir
# User authentication for channels
defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket

  channel "user:*", MyAppWeb.UserChannel

  def connect(_params, socket, connect_info) do
    # Extract token from headers or query params
    token = get_token(connect_info)

    case MyApp.Auth.verify_token(token) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}

      {:error, :invalid_token} ->
        :error
    end
  end

  def id(socket), do: "user_socket:#{socket.assigns.user_id}"

  defp get_token(connect_info) do
    # Check headers for token
    case get_req_header(connect_info, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end

# Channel with authorization
defmodule MyAppWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _payload, socket) do
    # Authorize user can only join their own channel
    if socket.assigns.user_id == String.to_integer(user_id) do
      send(self(), {:after_join, user_id})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:after_join, user_id}, socket) do
    # Send initial data after joining
    {:noreply, socket}
  end
end
```

## Channel Topics

### Dynamic Topics

```elixir
defmodule MyAppWeb.RoomChannel do
  use Phoenix.Channel

  # Join specific room
  def join("room:" <> room_id, _params, socket) do
    case MyApp.Rooms.get_room(room_id) do
      {:ok, room} ->
        # Track presence
        send(self(), {:after_join, room_id})
        {:ok, assign(socket, :room_id, room_id)}

      {:error, :not_found} ->
        {:error, %{reason: "room_not_found"}}
    end
  end

  # Join user's all rooms
  def join("rooms:user:" <> user_id, _params, socket) do
    rooms = MyApp.Rooms.list_user_rooms(user_id)
    {:ok, assign(socket, :rooms, rooms)}
  end

  def handle_info({:after_join, room_id}, socket) do
    # Send room history
    messages = MyApp.Chat.get_room_messages(room_id, limit: 50)
    push(socket, "messages_history", %{messages: messages})

    # Track presence
    MyApp.Presence.track(
      self(),
      "room:#{room_id}",
      socket.assigns.user_id,
      %{online_at: DateTime.utc_now() |> DateTime.to_iso8601()}
    )

    {:noreply, socket}
  end
end
```

### Hierarchical Topics

```elixir
# Organization hierarchy
defmodule MyAppWeb.OrganizationSocket do
  use Phoenix.Socket

  # Multiple channels with different permission levels
  channel "org:*", MyAppWeb.OrganizationChannel

  def connect(_params, socket, connect_info) do
    token = get_token(connect_info)

    case MyApp.Auth.verify_token(token) do
      {:ok, user} ->
        socket =
          socket
          |> assign(:user_id, user.id)
          |> assign(:org_id, user.organization_id)
          |> assign(:role, user.role)

        {:ok, socket}

      {:error, _} ->
        :error
    end
  end

  def id(socket), do: "org_socket:#{socket.assigns.user_id}"
end

defmodule MyAppWeb.OrganizationChannel do
  use Phoenix.Channel

  # Organization-wide channel
  def join("org:" <> org_id, _params, socket) do
    if socket.assigns.org_id == String.to_integer(org_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Team channel within organization
  def join("org:" <> org_id <> ":team:" <> team_id, _params, socket) do
    if socket.assigns.org_id == String.to_integer(org_id) and
         MyApp.Teams.member?(
           team_id,
           socket.assigns.user_id
         ) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
end
```

## Presence Tracking

### User Presence in Channels

```elixir
defmodule MyAppWeb.ChatChannel do
  use Phoenix.Channel

  def join("chat:" <> chat_id, _params, socket) do
    send(self(), {:after_join, chat_id})
    {:ok, socket}
  end

  def handle_info({:after_join, chat_id}, socket) do
    # Track user presence
    MyApp.Presence.track(
      self(),
      "chat:#{chat_id}",
      socket.assigns.user_id,
      %{
        online_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        username: socket.assigns.username
      }
    )

    # Send current presence list
    push(
      socket,
      "presence_state",
      MyApp.Presence.list("chat:#{chat_id}")
    )

    {:noreply, socket}
  end

  def handle_in("update_presence", payload, socket) do
    # Update user presence
    MyApp.Presence.update(
      self(),
      "chat:#{socket.assigns.chat_id}",
      socket.assigns.user_id,
      &Map.merge(&1, payload)
    )

    {:noreply, socket}
  end
end
```

## Message Broadcasting

### Broadcast to All Subscribers

```elixir
defmodule MyAppWeb.ChatChannel do
  use Phoenix.Channel

  def handle_in("new_message", %{"message" => message}, socket) do
    # Create message in database
    {:ok, saved_message} =
      MyApp.Chat.create_message(
        socket.assigns.chat_id,
        socket.assigns.user_id,
        message
      )

    # Broadcast to all subscribers
    broadcast!(socket, "message", saved_message)

    {:noreply, socket}
  end
end
```

### Broadcast to Specific Users

```elixir
# Send notifications to specific users
defmodule MyAppWeb.NotificationChannel do
  use Phoenix.Channel

  def join("notifications:" <> user_id, _params, socket) do
    if socket.assigns.user_id == String.to_integer(user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("send_notification", %{"user_id" => user_id, "message" => message}, socket) do
    # Check if sender is authorized to send notification
    if MyApp.Friends.friends?(socket.assigns.user_id, user_id) do
      # Create notification
      {:ok, notification} =
        MyApp.Notifications.create_notification(
          user_id,
          message
        )

      # Broadcast to specific user
      MyApp.Notifications.broadcast_to_user(user_id, notification)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end
end

# Broadcast helper
defmodule MyApp.Notifications do
  def broadcast_to_user(user_id, notification) do
    MyApp.PubSub.broadcast(
      MyApp.PubSub,
      "notifications:#{user_id}",
      {:new_notification, notification}
    )
  end
end
```

## Channel Rate Limiting

### Rate Limit Channel Events

```elixir
defmodule MyAppWeb.ChatChannel do
  use Phoenix.Channel

  @max_messages_per_minute 60

  def join("chat:" <> chat_id, _params, socket) do
    {:ok,
     socket
     |> assign(:message_count, 0)
     |> assign(:last_reset, DateTime.utc_now())}
  end

  def handle_in("new_message", %{"message" => message}, socket) do
    if rate_limit_exceeded?(socket) do
      push(socket, "error", %{reason: "rate_limit_exceeded"})
      {:noreply, socket}
    else
      # Create and broadcast message
      {:ok, saved_message} =
        MyApp.Chat.create_message(
          socket.assigns.chat_id,
          socket.assigns.user_id,
          message
        )

      broadcast!(socket, "message", saved_message)

      # Update rate limit counter
      socket = update_rate_limit(socket)

      {:noreply, socket}
    end
  end

  defp rate_limit_exceeded?(socket) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, socket.assigns.last_reset)

    # Reset counter every minute
    if elapsed > 60 do
      false
    else
      socket.assigns.message_count >= @max_messages_per_minute
    end
  end

  defp update_rate_limit(socket) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, socket.assigns.last_reset)

    if elapsed > 60 do
      # Reset counter
      assign(socket,
        message_count: 1,
        last_reset: now
      )
    else
      # Increment counter
      update(socket, :message_count, &(&1 + 1))
    end
  end
end
```

## Channel Error Handling

### Graceful Error Handling

```elixir
defmodule MyAppWeb.ChatChannel do
  use Phoenix.Channel

  def handle_in("new_message", %{"message" => message}, socket) do
    case MyApp.Chat.create_message(
           socket.assigns.chat_id,
           socket.assigns.user_id,
           message
         ) do
      {:ok, saved_message} ->
        broadcast!(socket, "message", saved_message)
        {:noreply, socket}

      {:error, changeset} ->
        # Send error to client
        push(socket, "error", %{
          reason: "validation_error",
          errors: format_errors(changeset)
        })

        {:noreply, socket}
    end
  end

  def handle_in("invalid_event", payload, socket) do
    # Handle unknown events
    push(socket, "error", %{reason: "unknown_event"})
    {:noreply, socket}
  end

  defp format_errors(changeset) do
    Enum.reduce(changeset.errors, %{}, fn {field, {message, _}}, acc ->
      Map.update(acc, field, [message], &(&1 ++ [message]))
    end)
  end
end
```

## Channel Authentication

### WebSocket vs HTTP Fallback

```elixir
defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket

  channel "user:*", MyAppWeb.UserChannel

  def connect(params, socket, connect_info) do
    # Try WebSocket authentication
    token = Map.get(params, "token")

    case MyApp.Auth.verify_token(token) do
      {:ok, user} ->
        {:ok, assign(socket, :user_id, user.id)}

      {:error, _} ->
        # Fallback to HTTP polling
        :error
    end
  end

  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
```

## Related Skills

- [Real-Time Patterns](../skills/realtime-patterns/SKILL.md) - Comprehensive real-time guide

## Related Patterns

- [LiveView Patterns](../liveview.md) - LiveView real-time patterns
- [Real-Time Patterns](../realtime_patterns.md) - General real-time patterns
