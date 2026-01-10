# Channel Testing Patterns

## Overview

Patterns for testing Phoenix Channels for real-time communication.

## Channel Connection Testing

### Testing Channel Join

```elixir
defmodule MyAppWeb.UserChannelTest do
  use MyAppWeb.ChannelCase

  describe "join/3" do
    test "user can join their own channel" do
      # Given: User and token
      user = insert(:user)
      token = MyApp.Auth.generate_token(user)

      # When: Join user's channel
      {:ok, _, socket} =
        subscribe_and_join(
          socket("user_socket:#{user.id}", %{token: token}),
          "user:#{user.id}"
        )

      # Then: Socket has user assigned
      assert socket.assigns.user_id == user.id
    end

    test "user cannot join another user's channel" do
      # Given: User and token
      user = insert(:user)
      token = MyApp.Auth.generate_token(user)
      other_user = insert(:user)

      # When: Try to join another user's channel
      assert {:error, %{reason: "unauthorized"}} =
               subscribe_and_join(
                 socket("user_socket:#{user.id}", %{token: token}),
                 "user:#{other_user.id}"
               )
    end

    test "unauthenticated user cannot join" do
      # When: Try to join without token
      assert {:error, %{reason: "unauthorized"}} =
               subscribe_and_join(
                 socket("user_socket:unknown", %{}),
                 "user:123"
               )
    end
  end
end
```

## Channel Event Testing

### Testing Incoming Events

```elixir
defmodule MyAppWeb.ChatChannelTest do
  use MyAppWeb.ChannelCase

  describe "handle_in/3" do
    test "broadcasts message to all subscribers" do
      # Given: Channel and subscribers
      {:ok, _, socket} =
        subscribe_and_join(
          socket("chat_socket", %{}),
          "chat:room1"
        )

      # Subscribe second user
      {:ok, _, socket2} =
        subscribe_and_join(
          socket("chat_socket2", %{}),
          "chat:room1"
        )

      # When: First user sends message
      push(socket, "new_message", %{message: "Hello, world!"})

      # Then: Both users receive broadcast
      assert_push("message", %{message: "Hello, world!"})
      assert_push("message", %{message: "Hello, world!"})
    end

    test "saves message to database" do
      # Given: Channel
      {:ok, _, socket} =
        subscribe_and_join(
          socket("chat_socket", %{}),
          "chat:room1"
        )

      # When: Send message
      push(socket, "new_message", %{message: "Test message"})

      # Then: Message is saved
      message = Repo.get_by(Message, text: "Test message")
      refute is_nil(message)
    end
  end
end
```

## Channel Presence Testing

### Testing User Presence

```elixir
defmodule MyAppWeb.PresenceChannelTest do
  use MyAppWeb.ChannelCase

  describe "presence/3" do
    test "tracks user when joining" do
      # Given: User
      user = insert(:user)

      # When: Join presence channel
      {:ok, _, socket} =
        subscribe_and_join(
          socket("presence_socket", %{}),
          "presence:room1"
        )

      # Then: User is tracked in presence
      send(self(), {:after_join, user.id})

      # Assert presence state
      assert_push("presence_state", presences)
      assert Map.has_key?(presences, to_string(user.id))
    end

    test "sends presence_diff on join" do
      # Given: Existing users in room
      user1 = insert(:user)
      user2 = insert(:user)

      {:ok, _, socket1} =
        subscribe_and_join(
          socket("presence_socket1", %{}),
          "presence:room1"
        )

      send(socket1.pid, {:after_join, user1.id})

      # When: Second user joins
      {:ok, _, socket2} =
        subscribe_and_join(
          socket("presence_socket2", %{}),
          "presence:room1"
        )

      # Then: First user receives presence diff
      assert_push("presence_diff", %{joins: joins, leaves: leaves})
      assert Map.has_key?(joins, to_string(user2.id))
      assert leaves == %{}
    end
  end
end
```

## Channel Authorization Testing

### Testing Channel Permissions

```elixir
defmodule MyAppWeb.TeamChannelTest do
  use MyAppWeb.ChannelCase

  describe "authorization" do
    test "team member can join team channel" do
      # Given: User and team
      user = insert(:user)
      team = insert(:team)

      insert(:team_member, user_id: user.id, team_id: team.id)

      # When: Join team channel
      {:ok, _, socket} =
        subscribe_and_join(
          socket("team_socket", %{user_id: user.id}),
          "team:#{team.id}"
        )

      # Then: Successfully joined
      assert socket.assigns.team_id == team.id
    end

    test "non-member cannot join team channel" do
      # Given: User and team (user is not member)
      user = insert(:user)
      team = insert(:team)

      # When: Try to join team channel
      assert {:error, %{reason: "unauthorized"}} =
               subscribe_and_join(
                 socket("team_socket", %{user_id: user.id}),
                 "team:#{team.id}"
               )
    end
  end
end
```

## Channel Broadcast Testing

### Testing Targeted Broadcasts

```elixir
defmodule MyAppWeb.NotificationChannelTest do
  use MyAppWeb.ChannelCase

  describe "broadcasts" do
    test "broadcasts to specific user" do
      # Given: User
      user = insert(:user)

      {:ok, _, socket} =
        subscribe_and_join(
          socket("user_socket", %{}),
          "notifications:#{user.id}"
        )

      # When: Send notification to user
      notification = %{message: "Test notification"}
      MyApp.Notifications.broadcast_to_user(user.id, notification)

      # Then: User receives notification
      assert_push("notification", ^notification)
    end

    test "other users do not receive notification" do
      # Given: Two users
      user1 = insert(:user)
      user2 = insert(:user)

      {:ok, _, socket1} =
        subscribe_and_join(
          socket("user_socket1", %{}),
          "notifications:#{user1.id}"
        )

      {:ok, _, socket2} =
        subscribe_and_join(
          socket("user_socket2", %{}),
          "notifications:#{user2.id}"
        )

      # When: Send notification to user1 only
      notification = %{message: "For user1 only"}
      MyApp.Notifications.broadcast_to_user(user1.id, notification)

      # Then: User1 receives notification
      assert_push("notification", ^notification)

      # Then: User2 does not receive notification
      refute_push("notification", _)
    end
  end
end
```

## Channel Error Handling Testing

### Testing Error Responses

```elixir
defmodule MyAppWeb.ChatChannelTest do
  use MyAppWeb.ChannelCase

  describe "error handling" do
    test "returns error for invalid message" do
      # Given: Channel
      {:ok, _, socket} =
        subscribe_and_join(
          socket("chat_socket", %{}),
          "chat:room1"
        )

      # When: Send invalid message
      push(socket, "invalid_event", %{data: "test"})

      # Then: Receive error response
      assert_push("error", %{reason: "unknown_event"})
    end

    test "returns error for validation failure" do
      # Given: Channel
      {:ok, _, socket} =
        subscribe_and_join(
          socket("chat_socket", %{}),
          "chat:room1"
        )

      # When: Send message without required field
      push(socket, "new_message", %{invalid: "data"})

      # Then: Receive validation error
      assert_push("error", %{
        reason: "validation_error",
        errors: %{message: ["is required"]}
      })
    end
  end
end
```

## Channel Rate Limit Testing

### Testing Rate Limiting

```elixir
defmodule MyAppWeb.ChatChannelTest do
  use MyAppWeb.ChannelCase

  describe "rate limiting" do
    test "allows normal message rate" do
      # Given: Channel
      {:ok, _, socket} =
        subscribe_and_join(
          socket("chat_socket", %{}),
          "chat:room1"
        )

      # When: Send messages at normal rate
      Enum.each(1..10, fn i ->
        push(socket, "new_message", %{message: "Message #{i}"})
        Process.sleep(100)
      end)

      # Then: All messages are processed
      Enum.each(1..10, fn i ->
        assert_push("message", %{message: "Message #{i}"})
      end)
    end

    test "blocks excessive message rate" do
      # Given: Channel
      {:ok, _, socket} =
        subscribe_and_join(
          socket("chat_socket", %{}),
          "chat:room1"
        )

      # When: Send 100 messages rapidly
      Enum.each(1..100, fn i ->
        push(socket, "new_message", %{message: "Message #{i}"})
      end)

      # Then: Receive rate limit error
      assert_push("error", %{reason: "rate_limit_exceeded"})
    end
  end
end
```

## Channel Disconnect Testing

### Testing Disconnection

```elixir
defmodule MyAppWeb.ChatChannelTest do
  use MyAppWeb.ChannelCase

  describe "disconnect/2" do
    test "updates presence on disconnect" do
      # Given: User in presence
      user = insert(:user)

      {:ok, _, socket} =
        subscribe_and_join(
          socket("presence_socket", %{}),
          "presence:room1"
        )

      send(socket.pid, {:after_join, user.id})

      # When: User disconnects
      Process.unlink(socket.pid)
      Process.exit(socket.pid, :normal)

      # Then: Presence diff shows user left
      assert_push("presence_diff", %{joins: %{}, leaves: leaves})
      assert Map.has_key?(leaves, to_string(user.id))
    end
  end
end
```

## Related Skills

- [Advanced Testing](../skills/advanced-testing/SKILL.md) - Comprehensive testing guide

## Related Patterns

- [LiveView Testing](../liveview_testing.md) - LiveView testing patterns
- [ExUnit Testing](../exunit_testing.md) - Unit testing patterns
