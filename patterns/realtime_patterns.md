# Real-Time Patterns

## Overview

Patterns for implementing real-time features in Elixir applications.

## PubSub Architecture

### Topic-Based Publishing

```elixir
# Define topics
defmodule MyApp.Topics do
  def topic_chat, do: "chat"
  def topic_notifications(user_id), do: "notifications:#{user_id}"
  def topic_presence(chat_id), do: "presence:#{chat_id}"
end

# Publish events
defmodule MyApp.Chat do
  def send_message(chat_id, user_id, message) do
    with {:ok, message} <- create_message(chat_id, user_id, message) do
      # Broadcast to all subscribers
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        MyApp.Topics.topic_chat(),
        {:new_message, message}
      )

      {:ok, message}
    end
  end

  def notify_user(user_id, notification) do
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      MyApp.Topics.topic_notifications(user_id),
      {:new_notification, notification}
    )
  end
end

# Subscribe to topics
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    # Subscribe to chat messages
    Phoenix.PubSub.subscribe(MyApp.PubSub, MyApp.Topics.topic_chat())

    # Subscribe to user notifications
    Phoenix.PubSub.subscribe(
      MyApp.PubSub,
      MyApp.Topics.topic_notifications(socket.assigns.current_user.id)
    )

    {:ok, socket}
  end

  def handle_info({:new_message, message}, socket) do
    {:noreply, update(socket, :messages, &(&1 ++ [message]))}
  end

  def handle_info({:new_notification, notification}, socket) do
    {:noreply, update(socket, :notifications, &(&1 ++ [notification]))}
  end
end
```

### Fan-Out Messaging

```elixir
# Broadcast to multiple topics
defmodule MyApp.Broadcast do
  @moduledoc """
  Broadcasts messages to multiple subscribers simultaneously.
  """

  def broadcast_to_all(topics, message) do
    Enum.each(topics, fn topic ->
      Phoenix.PubSub.broadcast(MyApp.PubSub, topic, message)
    end)
  end

  def broadcast_to_chat_rooms(chat_rooms, message) do
    topics = Enum.map(chat_rooms, &("chat:#{&1}"))
    broadcast_to_all(topics, {:new_message, message})
  end

  def broadcast_to_users(user_ids, notification) do
    topics = Enum.map(user_ids, &("notifications:#{&1}"))
    broadcast_to_all(topics, {:new_notification, notification})
  end
end

# Usage
defmodule MyApp.Chat do
  def send_message_to_rooms(message, room_ids) do
    MyApp.Broadcast.broadcast_to_chat_rooms(room_ids, message)
  end

  def notify_users(notification, user_ids) do
    MyApp.Broadcast.broadcast_to_users(notification, user_ids)
  end
end
```

## Presence Tracking

### User Presence System

```elixir
# Presence tracking
defmodule MyApp.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, presences, presences) do
    {:ok, presences}
  end

  def list_presences(topic) do
    Phoenix.Presence.list(__MODULE__, topic)
  end

  def get_online_users(topic) do
    __MODULE__
    |> list_presences(topic)
    |> Enum.map(fn {user_id, _metas} -> user_id end)
  end

  def get_user_count(topic) do
    __MODULE__
    |> list_presences(topic)
    |> length()
  end
end

# Track presence in LiveView
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    topic = "chat:#{socket.assigns.chat_id}"

    Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

    # Track user presence
    MyApp.Presence.track(self(), topic, socket.assigns.current_user.id, %{
      online_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      username: socket.assigns.current_user.username
    })

    {:ok,
     socket
     |> assign(:online_users, MyApp.Presence.get_online_users(topic))
     |> assign(:online_count, MyApp.Presence.get_user_count(topic))}
  end

  def handle_info({:presence_diff, _}, socket) do
    topic = "chat:#{socket.assigns.chat_id}"

    {:noreply,
     socket
     |> assign(:online_users, MyApp.Presence.get_online_users(topic))
     |> assign(:online_count, MyApp.Presence.get_user_count(topic))}
  end

  def handle_params(_params, _uri, socket) do
    topic = "chat:#{socket.assigns.chat_id}"

    # Untrack presence when leaving
    if connected?(socket) do
      MyApp.Presence.untrack(self(), topic, socket.assigns.current_user.id)
    end

    {:noreply, socket}
  end
end
```

## Real-Time Updates

### Optimistic UI Updates

```elixir
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "chat")

    {:ok, assign(socket, :messages, [])}
  end

  def handle_event("send_message", %{"message" => message_text}, socket) do
    # Create temporary message for optimistic update
    temp_message = %{
      id: nil,
      text: message_text,
      user: socket.assigns.current_user,
      inserted_at: DateTime.utc_now(),
      pending: true
    }

    # Optimistically update UI
    socket = update(socket, :messages, &(&1 ++ [temp_message]))

    # Send message to server
    send(self(), {:create_message, message_text, temp_message})

    {:noreply, socket}
  end

  def handle_info({:create_message, message_text, temp_message}, socket) do
    case MyApp.Chat.create_message(
           socket.assigns.current_user.id,
           message_text
         ) do
      {:ok, message} ->
        # Replace temp message with actual message
        messages =
          Enum.map(socket.assigns.messages, fn m ->
            if m.pending and m.text == message_text do
              message
            else
              m
            end
          end)

        {:noreply, assign(socket, :messages, messages)}

      {:error, _changeset} ->
        # Remove temp message on error
        messages =
          Enum.filter(socket.assigns.messages, &(!(&1.pending && &1.text == message_text)))

        {:noreply, assign(socket, :messages, messages)}
    end
  end

  def handle_info({:new_message, message}, socket) do
    {:noreply, update(socket, :messages, &(&1 ++ [message]))}
  end
end
```

## Rate Limiting for Real-Time

### Debouncing Messages

```elixir
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "chat")

    {:ok,
     socket
     |> assign(:messages, [])
     |> assign(:typing_users, [])}
  end

  def handle_event("typing", _params, socket) do
    # Debounce typing indicator
    send(self(), :debounce_typing)

    {:noreply, socket}
  end

  def handle_info(:debounce_typing, socket) do
    # Broadcast typing indicator
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "chat",
      {:user_typing, socket.assigns.current_user.id}
    )

    # Clear typing indicator after 3 seconds
    Process.send_after(self(), :clear_typing, 3000)

    {:noreply, socket}
  end

  def handle_info(:clear_typing, socket) do
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "chat",
      {:user_stopped_typing, socket.assigns.current_user.id}
    )

    {:noreply, socket}
  end

  def handle_info({:user_typing, user_id}, socket) do
    if user_id != socket.assigns.current_user.id do
      {:noreply, update(socket, :typing_users, &(&1 ++ [user_id]))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:user_stopped_typing, user_id}, socket) do
    {:noreply, update(socket, :typing_users, &(&1 -- [user_id]))}
  end
end
```

## Real-Time Search

### Live Search Updates

```elixir
defmodule MyAppWeb.SearchLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "search_results")

    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:results, [])}
  end

  def handle_event("search", %{"query" => query}, socket) do
    # Debounce search
    send(self(), {:debounce_search, query})

    {:noreply, assign(socket, :query, query)}
  end

  def handle_info({:debounce_search, query}, socket) do
    if String.length(query) >= 3 do
      # Perform search
      results = MyApp.Search.search(query)

      # Broadcast results to other tabs/windows
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "search_results",
        {:search_results, query, results}
      )

      {:noreply, assign(socket, :results, results)}
    else
      {:noreply, assign(socket, :results, [])}
    end
  end

  def handle_info({:search_results, query, results}, socket) do
    if socket.assigns.query == query do
      {:noreply, assign(socket, :results, results)}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="search-container">
      <form phx-submit="search">
        <input
          type="text"
          name="query"
          value={@query}
          placeholder="Search..."
          phx-debounce="300"
        />
        <button type="submit">Search</button>
      </form>

      <div class="results">
        <%= for result <- @results do %>
          <div class="result">
            <%= result.title %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
```

## Related Skills

- [Real-Time Patterns](../skills/realtime-patterns/SKILL.md) - Comprehensive real-time guide

## Related Patterns

- [LiveView Patterns](../liveview.md) - LiveView-specific patterns
- [Channels Patterns](../channels_patterns.md) - Phoenix Channels patterns
