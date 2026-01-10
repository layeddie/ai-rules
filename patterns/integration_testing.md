# Integration Testing Patterns

## Overview

Patterns for testing integrations between components in Elixir applications.

## Database Integration Tests

### Testing Multi-Table Transactions

```elixir
defmodule MyApp.WorkflowsTest do
  use MyApp.DataCase

  describe "order processing workflow" do
    test "creates order, payments, and updates inventory" do
      # Given: User, product, and inventory
      user = insert(:user)
      product = insert(:product, stock: 10)
      insert(:inventory, product_id: product.id, quantity: 10)

      # When: Process order
      order_attrs = %{
        user_id: user.id,
        items: [%{product_id: product.id, quantity: 2}]
      }

      assert {:ok, order} = Orders.process_order(order_attrs)

      # Then: Order is created with correct status
      assert order.status == :paid
      assert order.user_id == user.id

      # Then: Payment is created
      payment = Repo.get_by(Payment, order_id: order.id)
      refute is_nil(payment)
      assert payment.status == :success

      # Then: Inventory is updated
      inventory = Repo.get_by(Inventory, product_id: product.id)
      assert inventory.quantity == 8  # 10 - 2
    end

    test "rolls back transaction on payment failure" do
      # Given: User and product
      user = insert(:user)
      product = insert(:product, stock: 10)
      insert(:inventory, product_id: product.id, quantity: 10)

      # Mock payment service to fail
      expect(PaymentGateway, :charge, fn _ ->
        {:error, :payment_declined}
      end)

      # When: Process order with failing payment
      order_attrs = %{
        user_id: user.id,
        items: [%{product_id: product.id, quantity: 2}]
      }

      assert {:error, :payment_failed} = Orders.process_order(order_attrs)

      # Then: No order is created
      assert Repo.all(Order) == []

      # Then: No payment is created
      assert Repo.all(Payment) == []

      # Then: Inventory remains unchanged
      inventory = Repo.get_by(Inventory, product_id: product.id)
      assert inventory.quantity == 10
    end
  end
end
```

## API Integration Tests

### Testing External Service Integration

```elixir
defmodule MyApp.ExternalAPITest do
  use MyApp.DataCase

  import Mox

  setup :verify_on_exit!

  describe "user registration" do
    test "sends welcome email via external service" do
      # Given: User attributes
      attrs = %{
        email: "test@example.com",
        password: "password123"
      }

      # Mock external email service
      expect(ExternalEmail, :send_email, fn email, subject, body ->
        assert email == "test@example.com"
        assert subject == "Welcome to MyApp"
        assert body =~ "Welcome"
        {:ok, %{}}
      end)

      # When: Register user
      assert {:ok, user} = Accounts.register_user(attrs)

      # Then: Email service was called
      assert_called(ExternalEmail, :send_email, :_, :_, :_)
    end
  end

  describe "payment processing" do
    test "processes payment via Stripe" do
      # Given: Order
      order = insert(:order, amount: 100.0)

      # Mock Stripe API
      expect(Stripe.Client, :charge, fn amount, token ->
        assert amount == 100.0 * 100  # Convert to cents
        {:ok, %{id: "ch_123", status: "succeeded"}}
      end)

      # When: Process payment
      assert {:ok, payment} = Payments.process(order.id, "tok_visa")

      # Then: Payment is created
      assert payment.order_id == order.id
      assert payment.amount == 100.0
      assert payment.status == :success
      assert payment.provider_id == "ch_123"
    end
  end
end
```

## Cache Integration Tests

### Testing Cache Invalidation

```elixir
defmodule MyApp.CacheIntegrationTest do
  use MyApp.DataCase

  describe "user profile caching" do
    test "caches user profile on first access" do
      # Given: User in database
      user = insert(:user)

      # When: Access user profile (first time)
      profile = Profiles.get_profile(user.id)

      # Then: Cache miss, fetches from database
      assert profile.id == user.id

      # Then: Profile is cached
      assert Cache.get("user:#{user.id}:profile") == profile
    end

    test "returns cached profile on subsequent access" do
      # Given: User in database
      user = insert(:user)

      # When: Access user profile (first time)
      Profiles.get_profile(user.id)

      # When: Access again (should hit cache)
      profile = Profiles.get_profile(user.id)

      # Then: Returns cached profile
      assert profile.id == user.id
      assert not Repo.one(from p in Profile, where: p.id == ^user.id, select: count(p.id))
    end

    test "invalidates cache on profile update" do
      # Given: User and profile in database
      user = insert(:user)
      profile = insert(:profile, user_id: user.id)

      # When: Cache profile
      Profiles.get_profile(user.id)

      # When: Update profile
      Profiles.update_profile(profile.id, %{bio: "New bio"})

      # Then: Cache is invalidated
      assert is_nil(Cache.get("user:#{user.id}:profile"))

      # When: Access again
      updated_profile = Profiles.get_profile(user.id)

      # Then: Fetches updated profile from database
      assert updated_profile.bio == "New bio"
    end
  end
end
```

## PubSub Integration Tests

### Testing Real-Time Broadcasts

```elixir
defmodule MyApp.PubSubIntegrationTest do
  use MyApp.DataCase

  describe "notification broadcasts" do
    test "broadcasts notification to user" do
      # Given: User
      user = insert(:user)

      # Subscribe to user's notifications
      topic = "notifications:#{user.id}"
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

      # When: Send notification
      notification = %{message: "Test notification"}
      Notifications.broadcast_to_user(user.id, notification)

      # Then: Receive notification
      assert_receive {:new_notification, ^notification}, 1000
    end

    test "broadcasts to multiple users" do
      # Given: Multiple users
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)

      # Subscribe all users
      Phoenix.PubSub.subscribe(MyApp.PubSub, "notifications:#{user1.id}")
      Phoenix.PubSub.subscribe(MyApp.PubSub, "notifications:#{user2.id}")
      Phoenix.PubSub.subscribe(MyApp.PubSub, "notifications:#{user3.id}")

      # When: Broadcast to all users
      notification = %{message: "Broadcast to all"}
      Notifications.broadcast_to_users([user1.id, user2.id, user3.id], notification)

      # Then: All users receive notification
      assert_receive {:new_notification, ^notification}, 1000
      assert_receive {:new_notification, ^notification}, 1000
      assert_receive {:new_notification, ^notification}, 1000
    end
  end
end
```

## Workflow Integration Tests

### Testing Multi-Step Workflows

```elixir
defmodule MyApp.OnboardingWorkflowTest do
  use MyApp.DataCase

  describe "user onboarding" do
    test "completes full onboarding workflow" do
      # Given: New user
      user = insert(:user, status: :new, onboarding_step: nil)

      # Step 1: Send verification email
      {:ok, user} = Onboarding.start_onboarding(user)

      assert user.status == :verification_pending
      assert_email_sent(
        to: user.email,
        subject: "Verify your email"
      )

      # Step 2: Verify email
      token = user.verification_token
      {:ok, user} = Onboarding.verify_email(token)

      assert user.status == :verified
      assert user.onboarding_step == :profile_setup

      # Step 3: Setup profile
      profile_attrs = %{
        first_name: "John",
        last_name: "Doe",
        bio: "Software developer"
      }

      {:ok, user} = Onboarding.setup_profile(user, profile_attrs)

      assert user.status == :profile_complete
      assert user.onboarding_step == :payment_setup

      # Step 4: Setup payment
      payment_attrs = %{
        card_token: "tok_visa"
      }

      {:ok, user} = Onboarding.setup_payment(user, payment_attrs)

      assert user.status == :payment_complete
      assert user.onboarding_step == :complete

      # Then: User is fully onboarded
      assert user.onboarding_step == :complete
      assert user.status == :active
    end
  end
end
```

## Related Skills

- [Advanced Testing](../skills/advanced-testing/SKILL.md) - Comprehensive testing guide

## Related Patterns

- [ExUnit Testing](../exunit_testing.md) - Unit testing patterns
- [LiveView Patterns](../liveview.md) - LiveView testing patterns
