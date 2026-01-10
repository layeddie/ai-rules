# Advanced Testing Skill

## Overview

Comprehensive guide to advanced testing strategies for Elixir applications beyond basic unit testing.

## When to Use Advanced Testing

**Use advanced testing when:**
- Testing complex integrations between components
- Verifying end-to-end user workflows
- Testing concurrent and distributed systems
- Ensuring performance and load characteristics
- Validating real-time features (LiveView, Channels)

**Use basic testing when:**
- Testing pure functions (unit tests)
- Simple business logic verification
- Quick feedback during development

## Integration Testing

### DO: Test Multi-Component Interactions

```elixir
defmodule MyApp.WorkflowTest do
  use MyApp.DataCase

  describe "user registration workflow" do
    test "creates user, profile, and sends welcome email" do
      # Given: User registration data
      attrs = %{
        email: "test@example.com",
        password: "password123",
        first_name: "John",
        last_name: "Doe"
      }

      # When: Register user
      assert {:ok, user} = Accounts.register_user(attrs)

      # Then: User is created
      assert user.email == "test@example.com"

      # Then: Profile is created
      assert {:ok, profile} = Profiles.get_profile(user.id)
      assert profile.first_name == "John"
      assert profile.last_name == "Doe"

      # Then: Welcome email is sent
      assert_email_sent(
        to: "test@example.com",
        subject: "Welcome to MyApp"
      )
    end
  end

  describe "payment processing workflow" do
    test "processes payment and updates order status" do
      # Given: User and order
      user = insert(:user)
      order = insert(:order, user_id: user.id, status: :pending)

      payment_params = %{
        order_id: order.id,
        amount: order.total,
        payment_method: "credit_card"
      }

      # When: Process payment
      assert {:ok, payment} = Payments.process(payment_params)

      # Then: Payment is created
      assert payment.amount == order.total
      assert payment.status == :success

      # Then: Order status is updated
      assert {:ok, updated_order} = Orders.get_order(order.id)
      assert updated_order.status == :paid

      # Then: Receipt email is sent
      assert_email_sent(
        to: user.email,
        subject: "Payment Receipt"
      )
    end
  end
end
```

## End-to-End Testing

### Wallaby for E2E Tests

```elixir
defmodule MyApp.Web.EndToEndTest do
  use MyAppWeb.EndpointCase
  import Wallaby

  setup do
    {:ok, session} = Wallaby.start_session()
    {:ok, session: session}
  end

  describe "user registration flow" do
    test "user can register and login", %{session: session} do
      # Navigate to registration page
      session
      |> visit("/register")
      |> assert_has(Query.css("h1", text: "Register"))

      # Fill registration form
      session
      |> fill_in(Query.text_field("Email"), with: "test@example.com")
      |> fill_in(Query.text_field("Password"), with: "password123")
      |> fill_in(Query.text_field("Confirm Password"), with: "password123")
      |> fill_in(Query.text_field("First Name"), with: "John")
      |> fill_in(Query.text_field("Last Name"), with: "Doe")

      # Submit form
      session
      |> click(Query.button("Register"))

      # Assert redirect to dashboard
      assert_has(session, Query.css("h1", text: "Dashboard"))

      # Assert welcome message
      assert_has(
        session,
        Query.css(".notification", text: "Welcome to MyApp")
      )
    end
  end

  describe "checkout flow" do
    test "user can complete checkout", %{session: session} do
      # Setup: User and cart
      user = insert(:user)
      product = insert(:product)

      # Login
      session
      |> visit("/login")
      |> fill_in(Query.text_field("Email"), with: user.email)
      |> fill_in(Query.text_field("Password"), with: "password123")
      |> click(Query.button("Login"))

      # Add product to cart
      session
      |> visit("/products/#{product.id}")
      |> click(Query.button("Add to Cart"))

      # Navigate to cart
      session
      |> visit("/cart")
      |> assert_has(Query.css("h1", text: "Shopping Cart"))

      # Proceed to checkout
      session
      |> click(Query.button("Checkout"))

      # Fill payment form
      session
      |> fill_in(Query.text_field("Card Number"), with: "4242 4242 4242 4242")
      |> fill_in(Query.text_field("Expiry"), with: "12/25")
      |> fill_in(Query.text_field("CVC"), with: "123")

      # Submit order
      session
      |> click(Query.button("Place Order"))

      # Assert order confirmation
      assert_has(
        session,
        Query.css("h1", text: "Order Confirmed")
      )
    end
  end
end
```

## LiveView Testing

### Testing LiveView Interactions

```elixir
defmodule MyAppWeb.ChatLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  test "user can send and receive messages", %{conn: conn} do
    user = insert(:user)
    chat_room = insert(:chat_room)

    {:ok, view, _html} =
      live(conn, ~p"/chat/#{chat_room.id}")

    # Send message
    view
    |> form("#message-form", message: "Hello, world!")
    |> render_submit()

    # Assert message appears
    assert has_element?(
      view,
      ".message",
      "Hello, world!"
    )
  end

  test "user sees typing indicators", %{conn: conn} do
    user = insert(:user)
    chat_room = insert(:chat_room)

    {:ok, view, _html} =
      live(conn, ~p"/chat/#{chat_room.id}")

    # Simulate typing event
    send(view.pid, {:user_typing, user.id})

    # Assert typing indicator appears
    assert has_element?(
      view,
      ".typing-indicator",
      "John is typing..."
    )
  end

  test "user presence is tracked", %{conn: conn} do
    user = insert(:user)
    chat_room = insert(:chat_room)

    {:ok, view, _html} =
      live(conn, ~p"/chat/#{chat_room.id}")

    # Simulate presence update
    send(view.pid, {:presence_diff, %{joins: %{user.id => %{online_at: DateTime.utc_now()}}}})

    # Assert user appears in online list
    assert has_element?(
      view,
      ".online-users .user",
      user.username
    )
  end
end
```

## Channel Testing

### Testing Channel Interactions

```elixir
defmodule MyAppWeb.UserChannelTest do
  use MyAppWeb.ChannelCase

  setup do
    user = insert(:user)
    token = MyApp.Auth.generate_token(user)

    {:ok, user: user, token: token}
  end

  describe "join/3" do
    test "user can join their own channel", %{user: user, token: token} do
      {:ok, _, socket} =
        subscribe_and_join(
          socket("user_socket:#{user.id}", %{token: token}),
          "user:#{user.id}"
        )

      assert socket.assigns.user_id == user.id
    end

    test "user cannot join another user's channel", %{user: user, token: token} do
      other_user = insert(:user)

      assert {:error, %{reason: "unauthorized"}} =
               subscribe_and_join(
                 socket("user_socket:#{user.id}", %{token: token}),
                 "user:#{other_user.id}"
               )
    end
  end

  describe "handle_in/3" do
    test "broadcasts notification to user", %{user: user, token: token} do
      {:ok, _, socket} =
        subscribe_and_join(
          socket("user_socket:#{user.id}", %{token: token}),
          "user:#{user.id}"
        )

      # Send notification
      push(socket, "new_notification", %{message: "Hello"})

      # Assert broadcast received
      assert_push("notification", %{message: "Hello"})
    end
  end

  describe "presence/3" do
    test "tracks user presence", %{user: user, token: token} do
      {:ok, _, socket} =
        subscribe_and_join(
          socket("user_socket:#{user.id}", %{token: token}),
          "user:#{user.id}"
        )

      # Track presence
      push(socket, "update_presence", %{})

      # Assert presence state
      assert_push("presence_state", presences)
      assert Map.has_key?(presences, to_string(user.id))
    end
  end
end
```

## Concurrent Testing

### Testing Race Conditions

```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase

  describe "concurrent updates" do
    test "prevents duplicate user creation on concurrent requests" do
      email = "test@example.com"
      attrs = %{email: email, password: "password123"}

      # Spawn 10 concurrent user creation requests
      tasks =
        for _ <- 1..10 do
          Task.async(fn ->
            Accounts.register_user(attrs)
          end)
        end

      # Wait for all tasks to complete
      results = Task.await_many(tasks, 5000)

      # Assert only one user was created
      successes =
        Enum.filter(results, fn
          {:ok, _} -> true
          _ -> false
        end)

      assert length(successes) == 1

      # Assert others returned unique constraint error
      errors =
        Enum.filter(results, fn
          {:error, _} -> true
          _ -> false
        end)

      assert length(errors) == 9
    end
  end
end
```

## Performance Testing

### Benchee for Benchmarking

```elixir
defmodule MyApp.Benchmark do
  def run do
    Benchee.run(%{
      "naive" => fn -> naive_approach() end,
      "optimized" => fn -> optimized_approach() end
    },
    memory_time: 2,
    reduction_time: 2
    )
  end

  defp naive_approach do
    # Implementation
  end

  defp optimized_approach do
    # Implementation
  end
end

# Run with: mix run benchmark.exs
```

## Test Fixtures and Factories

### ExMachina for Test Data

```elixir
defmodule MyApp.TestHelpers do
  use ExMachina

  def user_factory do
    %MyApp.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      first_name: "John",
      last_name: "Doe"
    }
  end

  def post_factory do
    %MyApp.Blog.Post{
      title: sequence(:title, &"Post #{&1}"),
      body: "This is a test post.",
      published: true
    }
  end

  def comment_factory do
    %MyApp.Blog.Comment{
      body: sequence(:body, &"Comment #{&1}")
    }
  end
end

# Usage in tests
defmodule MyApp.PostsTest do
  use MyApp.DataCase

  alias MyApp.TestHelpers

  test "creates post" do
    post = build(:post)
    assert {:ok, _post} = Repo.insert(post)
  end
end
```

## Common Pitfalls

### DON'T: Test Implementation Details

```elixir
# DON'T: Test implementation details
defmodule BadTest do
  test "calls internal function" do
    # Tests how function is implemented, not what it does
    assert_receive({:internal_call, _args})
  end
end

# DO: Test behavior
defmodule GoodTest do
  test "returns correct result" do
    result = SomeModule.function()
    assert result == expected_value
  end
end
```

## Related Skills

- [Test Generation](../test-generation/SKILL.md) - TDD and basic testing
- [Performance Profiling](../performance-profiling/SKILL.md) - Performance optimization

## Related Patterns

- [ExUnit Testing](../exunit_testing.md) - ExUnit patterns
- [LiveView Patterns](../liveview.md) - LiveView best practices
