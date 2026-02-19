# Event Sourcing Patterns for Distributed Systems
#
# Event sourcing stores all changes as a sequence of events.
# Combined with CQRS, it provides excellent scalability and auditability.
#
# Recommended libraries:
#   {:commanded, "~> 1.4"} - CQRS/ES framework
#   {:eventstore, "~> 1.4"} - Event store
#   {:eventstore_db, "~> 0.1"} - EventStoreDB client
#
# Key concepts:
# - Events are immutable facts
# - State is derived from event replay
# - Projections for read models
# - Snapshots for performance

defmodule MyApp.Event do
  @moduledoc """
  Base event structure.
  """

  defstruct [
    :event_id,
    :event_type,
    :aggregate_id,
    :aggregate_version,
    :data,
    :metadata,
    :created_at
  ]

  def new(type, aggregate_id, data, metadata \\ %{}) do
    %__MODULE__{
      event_id: generate_uuid(),
      event_type: type,
      aggregate_id: aggregate_id,
      aggregate_version: 1,
      data: data,
      metadata:
        Map.merge(metadata, %{
          correlation_id: generate_uuid(),
          causation_id: generate_uuid(),
          user_id: Map.get(metadata, :user_id),
          timestamp: DateTime.utc_now()
        }),
      created_at: DateTime.utc_now()
    }
  end

  def with_version(event, version) do
    %{event | aggregate_version: version}
  end

  defp generate_uuid do
    UUID.uuid4()
  end
end

defmodule MyApp.EventStore do
  @moduledoc """
  Event store for persisting and retrieving events.

  This is a simplified in-memory implementation.
  For production, use EventStore library or EventStoreDB.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Client API

  def append_to_stream(aggregate_id, expected_version, events) do
    GenServer.call(__MODULE__, {:append, aggregate_id, expected_version, events})
  end

  def read_stream_forward(aggregate_id, start_version \\ 0, count \\ 1_000) do
    GenServer.call(__MODULE__, {:read, aggregate_id, start_version, count})
  end

  def subscribe_to_all(subscriber, opts \\ []) do
    GenServer.call(__MODULE__, {:subscribe_all, subscriber, opts})
  end

  def subscribe_to_stream(aggregate_id, subscriber, opts \\ []) do
    GenServer.call(__MODULE__, {:subscribe_stream, aggregate_id, subscriber, opts})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok,
     %{
       streams: %{},
       subscribers: %{all: [], streams: %{}},
       global_position: 0
     }}
  end

  @impl true
  def handle_call({:append, aggregate_id, expected_version, events}, _from, state) do
    case append_events(aggregate_id, expected_version, events, state) do
      {:ok, new_state, appended_events} ->
        # Notify subscribers
        notify_subscribers(aggregate_id, appended_events, new_state)
        {:reply, {:ok, length(appended_events)}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:read, aggregate_id, start_version, count}, _from, state) do
    events = get_stream_events(aggregate_id, state)

    filtered =
      events
      |> Enum.filter(fn e -> e.aggregate_version > start_version end)
      |> Enum.take(count)

    {:reply, {:ok, filtered}, state}
  end

  @impl true
  def handle_call({:subscribe_all, subscriber, opts}, _from, state) do
    new_subscribers = [subscriber | state.subscribers.all]
    new_state = put_in(state, [:subscribers, :all], new_subscribers)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:subscribe_stream, aggregate_id, subscriber, opts}, _from, state) do
    stream_subscribers = Map.get(state.subscribers.streams, aggregate_id, [])
    new_stream_subscribers = [subscriber | stream_subscribers]
    new_subscribers = Map.put(state.subscribers.streams, aggregate_id, new_stream_subscribers)
    new_state = put_in(state, [:subscribers, :streams], new_subscribers)
    {:reply, :ok, new_state}
  end

  # Private functions

  defp append_events(aggregate_id, expected_version, events, state) do
    current_events = get_stream_events(aggregate_id, state)
    current_version = length(current_events)

    if expected_version != current_version and expected_version != :any do
      {:error, :concurrency_error}
    else
      versioned_events =
        events
        |> Enum.with_index()
        |> Enum.map(fn {event, index} ->
          MyApp.Event.with_version(event, current_version + index + 1)
        end)

      new_stream = current_events ++ versioned_events
      new_streams = Map.put(state.streams, aggregate_id, new_stream)
      new_state = %{state | streams: new_streams}

      {:ok, new_state, versioned_events}
    end
  end

  defp get_stream_events(aggregate_id, state) do
    Map.get(state.streams, aggregate_id, [])
  end

  defp notify_subscribers(aggregate_id, events, state) do
    # Notify all subscribers
    Enum.each(state.subscribers.all, fn subscriber ->
      send(subscriber, {:events, events})
    end)

    # Notify stream subscribers
    stream_subscribers = Map.get(state.subscribers.streams, aggregate_id, [])

    Enum.each(stream_subscribers, fn subscriber ->
      send(subscriber, {:events, events})
    end)
  end
end

defmodule MyApp.Aggregate do
  @moduledoc """
  Base behaviour for aggregates in event sourcing.
  """

  @callback apply_event(event :: struct(), state :: map()) :: map()
  @callback execute_command(command :: struct(), state :: map()) ::
              {:ok, list(struct())} | {:error, term()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MyApp.Aggregate

      def new(aggregate_id) do
        %{
          id: aggregate_id,
          version: 0,
          state: initial_state(),
          pending_events: []
        }
      end

      def load(aggregate_id, events) do
        Enum.reduce(events, new(aggregate_id), fn event, aggregate ->
          apply_event_to_aggregate(event, aggregate)
        end)
      end

      def execute(aggregate, command) do
        case execute_command(command, aggregate.state) do
          {:ok, events} ->
            new_aggregate =
              Enum.reduce(events, aggregate, fn event, agg ->
                apply_event_to_aggregate(event, agg)
              end)

            {:ok, new_aggregate, events}

          error ->
            error
        end
      end

      defp apply_event_to_aggregate(event, aggregate) do
        new_state = apply_event(event, aggregate.state)
        new_version = aggregate.version + 1

        %{
          aggregate
          | state: new_state,
            version: new_version,
            pending_events: aggregate.pending_events ++ [event]
        }
      end

      def clear_pending_events(aggregate) do
        %{aggregate | pending_events: []}
      end

      # Override in implementing module
      def initial_state, do: %{}
      defoverridable initial_state: 0
    end
  end
end

defmodule MyApp.BankAccount do
  @moduledoc """
  Example aggregate: Bank Account with event sourcing.
  """

  use MyApp.Aggregate

  # Commands
  defmodule OpenAccount do
    defstruct [:account_id, :initial_balance, :owner_id]
  end

  defmodule DepositMoney do
    defstruct [:account_id, :amount]
  end

  defmodule WithdrawMoney do
    defstruct [:account_id, :amount]
  end

  # Events
  defmodule AccountOpened do
    defstruct [:account_id, :initial_balance, :owner_id, :opened_at]
  end

  defmodule MoneyDeposited do
    defstruct [:account_id, :amount, :balance, :deposited_at]
  end

  defmodule MoneyWithdrawn do
    defstruct [:account_id, :amount, :balance, :withdrawn_at]
  end

  defmodule WithdrawalRejected do
    defstruct [:account_id, :amount, :balance, :reason, :rejected_at]
  end

  # Aggregate callbacks

  @impl true
  def initial_state do
    %{status: :closed, balance: 0, owner_id: nil, opened_at: nil}
  end

  @impl true
  def execute_command(%OpenAccount{} = cmd, state) do
    if state.status == :closed do
      event = %AccountOpened{
        account_id: cmd.account_id,
        initial_balance: cmd.initial_balance,
        owner_id: cmd.owner_id,
        opened_at: DateTime.utc_now()
      }

      {:ok, [event]}
    else
      {:error, :account_already_open}
    end
  end

  @impl true
  def execute_command(%DepositMoney{} = cmd, state) do
    if state.status == :open do
      event = %MoneyDeposited{
        account_id: cmd.account_id,
        amount: cmd.amount,
        balance: state.balance + cmd.amount,
        deposited_at: DateTime.utc_now()
      }

      {:ok, [event]}
    else
      {:error, :account_closed}
    end
  end

  @impl true
  def execute_command(%WithdrawMoney{} = cmd, state) do
    cond do
      state.status != :open ->
        {:error, :account_closed}

      state.balance < cmd.amount ->
        event = %WithdrawalRejected{
          account_id: cmd.account_id,
          amount: cmd.amount,
          balance: state.balance,
          reason: :insufficient_funds,
          rejected_at: DateTime.utc_now()
        }

        {:ok, [event]}

      true ->
        event = %MoneyWithdrawn{
          account_id: cmd.account_id,
          amount: cmd.amount,
          balance: state.balance - cmd.amount,
          withdrawn_at: DateTime.utc_now()
        }

        {:ok, [event]}
    end
  end

  @impl true
  def apply_event(%AccountOpened{} = event, state) do
    %{
      state
      | status: :open,
        balance: event.initial_balance,
        owner_id: event.owner_id,
        opened_at: event.opened_at
    }
  end

  @impl true
  def apply_event(%MoneyDeposited{} = event, state) do
    %{state | balance: event.balance}
  end

  @impl true
  def apply_event(%MoneyWithdrawn{} = event, state) do
    %{state | balance: event.balance}
  end

  @impl true
  def apply_event(%WithdrawalRejected{}, state) do
    state
  end
end

defmodule MyApp.Projection do
  @moduledoc """
  Base behaviour for read model projections.
  """

  @callback init(opts :: keyword()) :: {:ok, state :: term()}
  @callback handle_event(event :: struct(), state :: term()) :: {:ok, state :: term()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MyApp.Projection
      use GenServer

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl true
      def init(opts) do
        case init(opts) do
          {:ok, state} ->
            # Subscribe to event store
            MyApp.EventStore.subscribe_to_all(self())
            {:ok, state}

          error ->
            error
        end
      end

      @impl true
      def handle_info({:events, events}, state) do
        new_state =
          Enum.reduce(events, state, fn event, s ->
            case handle_event(event, s) do
              {:ok, new_s} -> new_s
              _ -> s
            end
          end)

        {:noreply, new_state}
      end
    end
  end
end

defmodule MyApp.AccountSummaryProjection do
  @moduledoc """
  Read model projection for account summaries.
  """

  use MyApp.Projection

  @impl true
  def init(_opts) do
    {:ok, %{accounts: %{}}}
  end

  @impl true
  def handle_event(%MyApp.BankAccount.AccountOpened{} = event, state) do
    account = %{
      id: event.account_id,
      owner_id: event.owner_id,
      balance: event.initial_balance,
      status: :open,
      transaction_count: 0,
      opened_at: event.opened_at
    }

    new_accounts = Map.put(state.accounts, event.account_id, account)
    {:ok, %{state | accounts: new_accounts}}
  end

  @impl true
  def handle_event(%MyApp.BankAccount.MoneyDeposited{} = event, state) do
    account = Map.get(state.accounts, event.account_id)

    if account do
      updated = %{
        account
        | balance: event.balance,
          transaction_count: account.transaction_count + 1
      }

      new_accounts = Map.put(state.accounts, event.account_id, updated)
      {:ok, %{state | accounts: new_accounts}}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_event(%MyApp.BankAccount.MoneyWithdrawn{} = event, state) do
    account = Map.get(state.accounts, event.account_id)

    if account do
      updated = %{
        account
        | balance: event.balance,
          transaction_count: account.transaction_count + 1
      }

      new_accounts = Map.put(state.accounts, event.account_id, updated)
      {:ok, %{state | accounts: new_accounts}}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_event(_event, state) do
    {:ok, state}
  end

  # Query API
  def get_account(account_id) do
    GenServer.call(__MODULE__, {:get_account, account_id})
  end

  def get_all_accounts do
    GenServer.call(__MODULE__, :get_all_accounts)
  end

  @impl true
  def handle_call({:get_account, account_id}, _from, state) do
    account = Map.get(state.accounts, account_id)
    {:reply, {:ok, account}, state}
  end

  @impl true
  def handle_call(:get_all_accounts, _from, state) do
    {:reply, {:ok, Map.values(state.accounts)}, state}
  end
end

# Commanded integration example (production)
#
# defmodule MyApp.App do
#   use Commanded.Application,
#     event_store: [
#       adapter: Commanded.EventStore.Adapters.EventStore,
#       event_store: MyApp.EventStore
#     ]
# end
#
# defmodule MyApp.BankRouter do
#   use Commanded.Commands.Router
#
#   dispatch [
#     MyApp.BankAccount.OpenAccount,
#     MyApp.BankAccount.DepositMoney,
#     MyApp.BankAccount.WithdrawMoney
#   ], to: MyApp.BankAccount, identity: :account_id
# end
#
# Usage:
# :ok = MyApp.App.dispatch(%MyApp.BankAccount.OpenAccount{
#   account_id: "acc-123",
#   initial_balance: 1000,
#   owner_id: "user-1"
# })
