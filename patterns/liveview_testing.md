# LiveView Testing Patterns

## Overview

Patterns for testing Phoenix LiveView components and interactions.

## LiveView Setup

### Basic LiveView Test

```elixir
defmodule MyAppWeb.PageLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "mount/3" do
    test "mounts successfully" do
      {:ok, _view, _html} = live_isolated(conn(~p"/"), PageLive)
    end

    test "assigns initial data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "h1", "Welcome to MyApp")
    end
  end
end
```

### LiveView with Authentication

```elixir
defmodule MyAppWeb.ProtectedLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :authenticate_user

  @tag :authenticated
  test "mounts with authenticated user", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, ~p"/protected")

    assert has_element?(view, "p", "Welcome, #{user.username}")
  end

  test "redirects to login if not authenticated", %{conn: conn} do
    conn = Map.delete(conn.assigns, :current_user)

    assert {:error, {:redirect, %{to: "/login"}} =
             live_isolated(conn, ~p"/protected", ProtectedLive)
  end
end
```

## LiveView Event Testing

### Testing Form Submissions

```elixir
defmodule MyAppWeb.UserFormLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "handle_event/3" do
    test "valid form submission", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/new")

      # Fill form
      view
      |> form("#user-form", user: %{
        email: "test@example.com",
        name: "John Doe"
      })
      |> render_submit("user_form")

      # Assert successful submission
      assert_redirected(view, ~p"/users")

      # Verify user created in database
      user = Repo.get_by(User, email: "test@example.com")
      refute is_nil(user)
    end

    test "invalid form submission shows errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/new")

      # Submit empty form
      view
      |> form("#user-form", user: %{
        email: "",
        name: ""
      })
      |> render_submit("user_form")

      # Assert errors displayed
      assert has_element?(view, ".error", "can't be blank")
    end
  end
end
```

### Testing Custom Events

```elixir
defmodule MyAppWeb.ChatLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "handle_event/3" do
    test "sends message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Send message
      view
      |> render_click("send_message", %{message: "Hello, world!"})

      # Assert message appears
      assert has_element?(view, ".message", "Hello, world!")
    end

    test "clears input after sending", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Send message
      view
      |> render_click("send_message", %{message: "Test message"})

      # Assert input is cleared
      assert view
             |> element("input[name=\"message\"]")
             |> render() =~ "value=\"\""
    end
  end
end
```

## LiveView Info Testing

### Testing PubSub Subscriptions

```elixir
defmodule MyAppWeb.NotificationLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "handle_info/2" do
    test "receives and displays notifications", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/notifications")

      # Subscribe to user's notifications
      Phoenix.PubSub.subscribe(MyApp.PubSub, "notifications:#{user.id}")

      # Broadcast notification
      notification = %{message: "New message from John"}
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "notifications:#{user.id}",
        {:new_notification, notification}
      )

      # Assert notification appears
      assert has_element?(view, ".notification", notification.message)
    end

    test "updates notification count", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/notifications")

      # Initially 0 notifications
      assert has_element?(view, ".notification-count", "0")

      # Broadcast notification
      notification = %{message: "New message"}
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "notifications:#{user.id}",
        {:new_notification, notification}
      )

      # Count updates to 1
      assert has_element?(view, ".notification-count", "1")
    end
  end
end
```

## LiveView Testing with Streams

### Testing Stream Updates

```elixir
defmodule MyAppWeb.ChatMessagesLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "stream updates" do
    test "renders initial messages", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat/messages")

      # Assert initial messages are rendered
      assert has_element?(view, "#messages .message", count: 10)
    end

    test "appends new message to stream", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/chat/messages")

      initial_count = view
                   |> element("#messages .message")
                   |> render()
                   |> String.split("<div class=\"message")
                   |> length()

      # Send new message
      view
      |> render_click("send_message", %{message: "New message"})

      # Assert new message appears
      new_count = view
                  |> element("#messages .message")
                  |> render()
                  |> String.split("<div class=\"message")
                  |> length()

      assert new_count == initial_count + 1
    end

    test "updates message in stream", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat/messages")

      # Edit message
      view
      |> render_click("edit_message", %{
        message_id: "msg_1",
        content: "Updated message"
      })

      # Assert message is updated
      assert has_element?(
        view,
        "#messages .message#msg_1",
        "Updated message"
      )
    end
  end
end
```

## LiveComponent Testing

### Testing Child Components

```elixir
defmodule MyAppWeb.UserProfileComponentTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "UserProfileComponent" do
    test "renders user profile", %{conn: conn, user: user} do
      {:ok, view, _html} =
        live_isolated(conn, ~p"/users/#{user.id}", MyAppWeb.UserLive)

      # Assert profile component is rendered
      assert has_element?(view, "#user-profile")

      # Assert user details
      assert has_element?(view, ".user-name", user.username)
      assert has_element?(view, ".user-email", user.email)
    end

    test "updates profile", %{conn: conn, user: user} do
      {:ok, view, _html} =
        live_isolated(conn, ~p"/users/#{user.id}", MyAppWeb.UserLive)

      # Update profile
      view
      |> element("#profile-form")
      |> render_change(%{
        user: %{
          bio: "New bio"
        }
      })

      # Assert bio is updated
      assert has_element?(view, ".user-bio", "New bio")
    end
  end
end
```

## LiveView File Upload Testing

### Testing File Uploads

```elixir
defmodule MyAppWeb.UploadLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "file uploads" do
    test "uploads valid file", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/upload")

      # Create temporary file
      file = %Plug.Upload{
        content_type: "image/png",
        filename: "test.png",
        path: Path.join([System.tmp_dir!(), "test.png"])
      }

      File.write!(file.path, "fake image data")

      # Submit file
      view
      |> file_input(:avatar, :files, [file])
      |> render_submit("upload")

      # Assert upload success
      assert_redirected(view, ~p"/profile")

      # Verify file is saved
      assert File.exists?(
               Path.join([
                 Application.app_dir(:my_app),
                 "priv",
                 "static",
                 "uploads",
                 file.filename
               ])
             )
    end

    test "validates file type", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/upload")

      # Try to upload invalid file type
      file = %Plug.Upload{
        content_type: "application/pdf",
        filename: "document.pdf",
        path: Path.join([System.tmp_dir!(), "document.pdf"])
      }

      File.write!(file.path, "fake pdf data")

      # Submit file
      view
      |> file_input(:avatar, :files, [file])
      |> render_submit("upload")

      # Assert validation error
      assert has_element?(view, ".error", "Invalid file type")
    end
  end
end
```

## LiveView Navigation Testing

### Testing Live Navigation

```elixir
defmodule MyAppWeb.PostLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "handle_params/3" do
    test "navigates between posts", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/1")

      # Assert first post is loaded
      assert has_element?(view, "h1", "Post 1")

      # Navigate to second post
      view
      |> render_click("next_post")

      # Assert second post is loaded
      assert has_element?(view, "h1", "Post 2")

      # Navigate to previous post
      view
      |> render_click("previous_post")

      # Assert first post is loaded again
      assert has_element?(view, "h1", "Post 1")
    end
  end
end
```

## Related Skills

- [Advanced Testing](../skills/advanced-testing/SKILL.md) - Comprehensive testing guide

## Related Patterns

- [LiveView Patterns](../liveview.md) - LiveView best practices
- [ExUnit Testing](../exunit_testing.md) - Unit testing patterns
