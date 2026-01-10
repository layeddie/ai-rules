# Real-Time Patterns Skill

## Overview

Comprehensive guide to implementing real-time features in Elixir applications using Phoenix LiveView, Phoenix Channels, and WebSockets.

## When to Use Real-Time Features

**Use real-time features when:**
- Users need instant updates (chat, notifications, live dashboards)
- Collaborative features are required (shared documents, whiteboards)
- Real-time monitoring or analytics
- Live auctions, sports scores, or stock tickers

**Use polling instead when:**
- Updates are infrequent (less than once per minute)
- Real-time is not a critical feature
- Server resources are limited
- Simpler implementation is preferred

## Phoenix LiveView Real-Time

### DO: Use LiveView for Server-Rendered Real-Time

```elixir
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    # Broadcast message to all connected clients
    broadcast_message(socket, message)
    {:noreply, socket}
  end

  defp broadcast_message(socket, message) do
    Phoenix.PubSub.broadcast(MyApp.PubSub, "chat", {:new_message, message})
  end

  def handle_info({:new_message, message}, socket) do
    # Update UI when new message arrives
    {:noreply, update(socket, :messages, &(&1 ++ [message]))}
  end

  def render(assigns) do
    ~H"""
    <div class="chat-container">
      <div class="messages">
        <%= for message <- @messages do %>
          <div class="message"><%= message %></div>
        <% end %>
      </div>

      <form phx-submit="send_message">
        <input type="text" name="message" placeholder="Type a message..." />
        <button type="submit">Send</button>
      </form>
    </div>
    """
  end
end
```

### DON'T: Use JavaScript Polling for LiveView Updates

```elixir
# DON'T: Use JavaScript polling
defmodule MyAppWeb.ChatLive do
  def render(assigns) do
    ~H"""
    <div id="messages">
      <!-- Messages -->
    </div>

    <script>
      // Poll for new messages
      setInterval(function() {
        fetch('/messages')
          .then(response => response.json())
          .then(messages => {
            updateMessages(messages);
          });
      }, 1000);  // Polling every second
    </script>
    """
  end
end

# DO: Use LiveView pub/sub
defmodule MyAppWeb.ChatLive do
  def mount(_params, _session, socket) do
    # Subscribe to message updates
    Phoenix.PubSub.subscribe(MyApp.PubSub, "chat")

    {:ok, assign(socket, :messages, [])}
  end

  def handle_info({:new_message, message}, socket) do
    # LiveView automatically updates UI
    {:noreply, update(socket, :messages, &(&1 ++ [message]))}
  end
end
```

## Phoenix Channels

### DO: Use Channels for Persistent Connections

```elixir
# User Channel
defmodule MyAppWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _payload, socket) do
    # Authorize connection
    if authorized?(user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new_notification", %{"message" => message}, socket) do
    # Broadcast notification to user
    broadcast!(socket, "notification", %{message: message})
    {:noreply, socket}
  end

  def handle_in("update_presence", payload, socket) do
    # Track user presence
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:second))
    })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  defp authorized?(user_id), do: true  # Implement authorization logic
end

# Usage in JavaScript client
let socket = new Socket("/socket", {params: {token: window.userToken}})

let channel = socket.channel("user:" + userId, {})

channel.join()
  .receive("ok", (resp) => { console.log("Joined successfully", resp) })
  .receive("error", (resp) => { console.log("Unable to join", resp) })

channel.on("notification", (payload) => {
  console.log("New notification:", payload)
})

socket.connect()
```

### DON'T: Handle Channel Joins Without Authorization

```elixir
# DON'T: Allow all joins without authorization
defmodule MyAppWeb.UserChannel do
  use Phoenix.Channel

  def join(_topic, _payload, socket) do
    {:ok, socket}  # Anyone can join!
  end
end

# DO: Implement authorization
defmodule MyAppWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _payload, socket) do
    if socket.assigns.user_id == String.to_integer(user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
end
```

## LiveView Presence

### DO: Use Presence for Real-Time User Tracking

```elixir
defmodule MyAppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, presences, presences) do
    # Track user presence
    {:ok, presences}
  end
end

defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    # Subscribe to presence updates
    Phoenix.PubSub.subscribe(MyApp.PubSub, "chat")
    MyAppWeb.Presence.track(self(), "chat", socket.assigns.current_user.id, %{
      online_at: DateTime.utc_now() |> DateTime.to_iso8601()
    })

    {:ok, assign(socket, :online_users, MyAppWeb.Presence.list("chat"))}
  end

  def handle_info({:presence_diff, _diff}, socket) do
    # Update online users
    {:noreply, assign(socket, :online_users, MyAppWeb.Presence.list("chat"))}
  end

  def render(assigns) do
    ~H"""
    <div class="online-users">
      <h3>Online Users</h3>
      <ul>
        <%= for {user_id, meta} <- @online_users do %>
          <li>
            <%= user_id %>
            <%= if length(meta) > 0, do: " (online)", else: "" %>
          </li>
        <% end %>
      </ul>
    </div>

    <div class="chat-messages">
      <!-- Chat messages -->
    </div>
    """
  end
end
```

## LiveView Streams

### DO: Use Streams for Efficient List Updates

```elixir
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "chat")

    {:ok,
     socket
     |> assign(:message_count, 0)
     |> stream(:messages, [])}
  end

  def handle_info({:new_message, message}, socket) do
    # Append message to stream
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    Phoenix.PubSub.broadcast(MyApp.PubSub, "chat", {:new_message, message})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="chat-container">
      <div id="messages" phx-update="stream">
        <%= for {id, message} <- @streams.messages do %>
          <div class="message" id={id}>
            <%= message.text %>
          </div>
        <% end %>
      </div>

      <form phx-submit="send_message">
        <input type="text" name="message" placeholder="Type a message..." />
        <button type="submit">Send</button>
      </form>
    </div>
    """
  end
end
```

## Real-Time Form Updates

### DO: Use LiveView for Real-Time Form Validation

```elixir
defmodule MyAppWeb.UserFormLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :changeset, User.changeset(%User{}))}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = User.changeset(%User{}, user_params)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    changeset = User.changeset(%User{}, user_params)

    case Accounts.create_user(changeset) do
      {:ok, user} ->
        {:noreply, put_flash(socket, :info, "User created successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="user-form">
      <h1>Create User</h1>

      <.form
        let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
      >
        <%= label(f, :name) %>
        <%= text_input(f, :name) %>
        <%= error_tag(f, :name) %>

        <%= label(f, :email) %>
        <%= email_input(f, :email) %>
        <%= error_tag(f, :email) %>

        <button type="submit">Save</button>
      </.form>
    </div>
    """
  end
end
```

## Real-Time Notifications

### DO: Use PubSub for Broadcast Notifications

```elixir
defmodule MyApp.Notifications do
  @moduledoc """
  Real-time notification system using Phoenix PubSub.
  """

  def broadcast_notification(user_id, message) do
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "notifications:#{user_id}",
      {:new_notification, message}
    )
  end

  def subscribe_to_notifications(user_id) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "notifications:#{user_id}")
  end
end

# Usage in LiveView
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    # Subscribe to notifications
    MyApp.Notifications.subscribe_to_notifications(socket.assigns.current_user.id)

    {:ok, assign(socket, :notifications, [])}
  end

  def handle_info({:new_notification, notification}, socket) do
    # Add notification to list
    {:noreply, update(socket, :notifications, &(&1 ++ [notification]))}
  end

  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <div class="notifications">
        <h2>Notifications</h2>
        <%= for notification <- @notifications do %>
          <div class="notification">
            <%= notification.message %>
          </div>
        <% end %>
      </div>

      <div class="content">
        <!-- Dashboard content -->
      </div>
    </div>
    """
  end
end
```

## Real-Time File Uploads

### DO: Use LiveUpload for Real-Time Progress

```elixir
defmodule MyAppWeb.UploadLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign(:uploaded_files, [])}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        dest = Path.join([:code.priv_dir(:my_app), "static", "uploads", entry.uuid])
        File.cp!(path, dest)
        Routes.static_path(socket, "/uploads/#{entry.uuid}")

        {:ok, Routes.static_path(socket, "/uploads/#{entry.uuid}")}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def render(assigns) do
    ~H"""
    <div class="upload-container">
      <h1>Upload Avatar</h1>

      <form id="upload-form" phx-submit="save" phx-change="validate">
        <.live_file_input upload={@uploads.avatar} />
        <button type="submit">Upload</button>
      </form>

      <%= for entry <- @uploads.avatar.entries do %>
        <div class="progress">
          <progress value={entry.progress} max="100">
            <%= entry.progress %>%
          </progress>
          <button phx-click="cancel-upload" phx-value-ref={entry.ref}>
            Cancel
          </button>
        </div>
      <% end %>

      <div class="uploaded-files">
        <%= for file <- @uploaded_files do %>
          <img src={file} alt="Uploaded avatar" />
        <% end %>
      </div>
    </div>
    """
  end
end
```

## Common Pitfalls

### DON'T: Ignore Performance in Real-Time Updates

```elixir
# DON'T: Update entire list on each change
defmodule BadExample do
  def handle_info({:new_message, message}, socket) do
    # Fetches all messages on every update
    messages = Messages.list_all()
    {:noreply, assign(socket, :messages, messages)}
  end
end

# DO: Use streams for efficient updates
defmodule GoodExample do
  def handle_info({:new_message, message}, socket) do
    # Only inserts new message
    {:noreply, stream_insert(socket, :messages, message)}
  end
end
```

## Related Skills

- [LiveView Patterns](../liveview-patterns/SKILL.md) - LiveView-specific patterns
- [Distributed Systems](../distributed-systems/SKILL.md) - PubSub patterns

## Related Patterns

- [LiveView](../liveview.md) - LiveView best practices
- [Phoenix Controllers](../phoenix_controllers.md) - API vs real-time
