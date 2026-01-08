# How to Code GenServers in Elixir

*Source: https://www.freshcodeit.com/blog/how-to-design-and-test-elixir-genservers?utm_source=elixir-merge*

## Key Takeaways

- Non-blocking callbacks keep schedulers healthy
- Move highly contended reads to ETS or `:persistent_term`, but understand the trade-offs
- Instrument first, optimise second
- Utilize supervision and back-pressure patterns to maintain resilience

## Resources & Further Reading

- Official OTP docs – `gen_server`, `:erlang.process_info/2`
- Fred Hébert – "Adopting Erlang/OTP" chapters on monitoring
- Saša Jurić – "Elixir in Action", sections on performance
- Erlang Solutions – "Designing for Scalability with Erlang/OTP"

---

The GenServer is a powerful abstraction for managing stateful processes and harnessing concurrency when working with Elixir. Often, not only newcomers but also experienced engineers are struggling with GenServer testing. In this article, we'll dive into ideas on how to properly design and test GenServers.

## Do You Really Need It?

> "Simple things should be simple, and complex things should be possible."
> — Rich Hickey, Creator of Clojure

GenServer (Generic Server) is one of the core building blocks in Elixir applications, implementing the actor model for concurrent state management. It gives us a notion of when GenServers shine:

1. **State Management** - When you need to maintain state between requests (e.g., caching, counters)
2. **Concurrency Control** - When you need to serialize access to resources
3. **Background Processing** - When you need to handle long-running tasks
4. **Resource Management** - When you need to manage connections or limited resources

Before diving into GenServer implementation, always reconsider if you need it. A key question is: "Does my process need to manage state over time or deal with inter-process coordination?" If the answer is no, then there's likely a better approach available. Many problems can be solved with simple structs and functions, avoiding the overhead and complexity of a full GenServer.

### Case Study: Elixir Telecom

**Company:** A local telecom provider delivering Internet and IoT services for businesses and homes.

**Challenge:** With tens of thousands of endpoints, the Java-based system handled just 5,000 devices per server, restricting scalability and flexibility.

**Solution:** Built a scalable Elixir-based system that automates SLA checks and integrates custom IoT devices, cutting operational costs by 25%.

**Technology:** Elixir, LiveDashboard, Nerves, Broadway, ElixirALE, Telemetry.

## GenServer Overhead

```elixir
defmodule CounterServer do
  use GenServer

  def start_link(initial_count) do
    GenServer.start_link(__MODULE__, initial_count, name: __MODULE__)
  end

  def init(initial_count), do: {:ok, initial_count}

  def increment, do: GenServer.call(__MODULE__, :increment)

  def handle_call(:increment, _from, count) do
    {:reply, count + 1, count + 1}
  end
end
```

This GenServer implementation comes with several forms of overhead:

- You need to start and manage a long-running process
- Each operation requires inter-process communication
- You need to handle process supervision and recovery
- Each process maintains its state in memory
- You need to implement callbacks and handle the process lifecycle

In cases where nothing from above is required, go for a more straightforward implementation:

### Simpler Alternative

```elixir
defmodule Counter do
  defstruct count: 0

  def increment(%Counter{count: count} = counter) do
    %Counter{counter | count: count + 1}
  end
end
```

## Why Proper Design Matters

> "If you can't test it, it's not a good design."
> — Kent Beck, Creator of Extreme Programming

One of the first principles to keep in mind when working with GenServers is the importance of design. With proper design, testing GenServers becomes at least possible and at most easier while the overall complexity of an application decreases.

### Common Design Flaws

#### Business Logic Overload

The GenServer should act primarily as a coordinator, passing off complex business logic to external modules. By keeping GenServers thin, you can make testing easier, as the business logic can be tested independently of the process. Let's examine a common anti-pattern where business logic is directly embedded in the GenServer:

**BL Overload Example**

```elixir
defmodule OrderProcessor do
  use GenServer

  def handle_call({:process_order, order}, _from, state) do
    # Complex business logic buried in GenServer
    validated_order = validate_order(order)
    total = calculate_total(validated_order)
    updated_inventory = update_inventory(validated_order)
    receipt = generate_receipt(validated_order, total)

    {:reply, receipt, Map.put(state, :inventory, updated_inventory)}
  end

  # Many private functions implementing business logic...
end
```

This implementation violates key principles of business logic separation:

1. **Testing complexity** – business logic is trapped inside process management, each test requires process overhead, it's hard to test business rules in isolation, and difficult to simulate different business scenarios

2. **Maintainability issues** – business rules are mixed with infrastructure concerns, changes to business logic risk affecting process stability, it's hard to adapt as business rules evolve, and difficult to reuse logic across different interfaces

3. **Context confusion** – there's no clear separation between business and infrastructure layers, business rules become tied to process lifecycle, it's hard to implement new interfaces like API or CLI, and difficult to maintain consistent authorization

Here's a better approach that separates process management from business logic:

**Better Approach**

```elixir
defmodule OrderProcessor do
  use GenServer

  def handle_call({:process_order, order}, _from, state) do
    # GenServer only coordinates the process
    {:ok, receipt, updated_inventory} = OrderService.process_order(order, state)

    {:reply, receipt, Map.put(state, :inventory, updated_inventory)}
  end
end
```

#### Treating GenServers like OOP Objects (Simple Data Management)

Misuse comes from developers with an object-oriented programming (OOP) background who treat GenServers like objects, trying to encapsulate state and business logic within them. This leads to overly complex and often untestable code.

#### Ignoring SRP

A well-designed GenServer should adhere to the single responsibility principle: it should focus on one task and do it well. This not only makes the GenServer more efficient, but it also simplifies testing. For example, in trading applications like those I work on, where real-time data streams need to be processed quickly, we assign each GenServer its specific task, such as processing orders or managing real-time market data. This helps ensure that no single GenServer becomes a bottleneck.

## Lean on Isolation and Mocking for Effective Testing

Now that we've covered proper GenServer design – keeping them thin, avoiding business logic overload, and maintaining single responsibility – let's explore how these principles enable straightforward testing. When your GenServers are well-designed, testing becomes natural and follows two main strategies:

### Isolated Callback Testing

When testing GenServers, you should apply a consistent strategy across different callbacks (handle_call, handle_cast, handle_info, etc.). Testing these callbacks directly by calling them in isolation allows you to focus on the specific state transitions without the overhead of running a GenServer. This is particularly useful for simple tests where you need to validate that the correct state is returned for given inputs.

### Live GenServer Testing

For more complex interactions, such as timeouts or retries with external services, it's often necessary to run the GenServer itself. Jose Valim established these testing strategies in his article about mocks and explicit contracts. Let's look at how to implement them:

#### Functional Testing with Live GenServer

When you deal with modules/services that you cannot control (or you don't want to control), you can wrap them into facades with explicit contracts and different adapters for different environments (test, dev, prod). Let's take a look at an example:

```elixir
defmodule Mailer.Adapter do
  @callback send_email(to :: String.t(), subject :: String.t(), body :: String.t()) :: :ok
end

defmodule Mailer.Stub do
  @behaviour Mailer.Adapter

  def send_email(_to, _subject, _body), do: :ok
end

defmodule YourEmailService do
  @behaviour Mailer.Adapter

  def send_email(_to, _subject, _body) do
    # you actually send an email here using your email service
  end
end
```

Let's say we have a GenServer which sends an email after processing an order. By having an explicit contract, we can easily swap the implementation for testing purposes.

#### Case 1: When We Don't Need to Swap the Implementation

In that case, we can use the Stub implementation.

```elixir
# somewhere in your test.exs file
config :my_app, :mailer, Mailer.Stub

defmodule OrderProcessor do
  use GenServer

  # in that case, Stub is baked into the GenServer, allowing us to focus on the business logic
  @mailer Application.compile_env(:my_app, :mailer)

  def handle_call({:process_order, order}, _from, state) do
    # ...
    @mailer.send_email(order.email, "Order Confirmation", "Thank you for your order!")
    # ...
  end
end
```

#### Case 2: When We NEED to Swap the Implementation

In that case, we could pass the implementation as an option to the GenServer so that details could be changed on the test level.

```elixir
defmodule OrderProcessor do
  def start_link(opts) do
    mailer = Keyword.fetch!(opts, :mailer)
    GenServer.start_link(__MODULE__, %{mailer: mailer}, name: __MODULE__)
  end

  # ...

  def handle_call({:process_order, order}, _from, state) do
    # ...
    case state.mailer.send_email(order.email, "Order Confirmation", "Thank you for your order!") do
      :ok -> # ...
      {:error, reason} -> # ...
    end
    # ...
  end
end

defmodule FailingMailer do
  @behaviour Mailer.Adapter

  def send_email(_to, _subject, _body), do: {:error, "Failed to send email"}
end

describe "handle_call/3" do
  test "processes an order correctly" do
    # ...
    OrderProcessor.start_link(mailer: FailingMailer)
    # ...
  end
end
```

## Conclusion

What have we learned about working with GenServers?

**First**, not every problem needs a GenServer. Simple structs and functions are often enough – avoid the process management overhead unless you really need that persistent state or coordination between processes.

**Second**, when you do need a GenServer, keep it thin. Let it coordinate processes while keeping business logic elsewhere. You'll thank yourself later when testing and maintaining the code. Remember that mixing business rules with process management is a recipe for complexity.

**Finally**, testing well-designed GenServers doesn't have to be hard. Test simple state transitions by calling callbacks directly. Use proper contracts and dependency injection for more complex cases involving external services – either through configuration or runtime.

The bottom line? If testing feels difficult, your GenServer might be doing too much. Let that guide you toward better design decisions.
