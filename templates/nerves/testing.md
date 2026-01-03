# Nerves Testing Template

## Test Structure

```
test/
├── test_helper.exs
├── test/support/
│   ├── hardware_mocks.exs
│   ├── fixtures.exs
│   └── helpers.exs
└── my_app/
    ├── hardware/
    │   ├── motor_test.exs
    │   ├── load_cell_test.exs
    │   └── limit_switch_test.exs
    ├── control/
    │   ├── tension_test.exs
    │   ├── calibration_test.exs
    │   └── safety_test.exs
    └── ui/
        ├── display_test.exs
        ├── control_panel_test.exs
        └── web_server_test.exs
```

## test/test_helper.exs

```elixir
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, :manual)
```

## test/support/hardware_mocks.exs

```elixir
defmodule MyApp.Test.HardwareMocks do
  @moduledoc """
  Mock implementations for hardware components.
  """

  defmodule MockMotor do
    @moduledoc false
    use GenServer

    def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

    def init(_opts) do
      {:ok, %{position: 0, enabled: false, state: :idle}}
    end

    def handle_call({:move, position}, _from, state) do
      {:reply, :ok, %{state | position: position, state: :moving}}
    end

    def handle_call(:stop, _from, state) do
      {:reply, :ok, %{state | state: :idle}}
    end

    def handle_call(:get_position, _from, state) do
      {:reply, state.position, state}
    end

    def handle_call(:enable, _from, state) do
      {:reply, :ok, %{state | enabled: true}}
    end

    def handle_call(:disable, _from, state) do
      {:reply, :ok, %{state | enabled: false}}
    end
  end

  defmodule MockLoadCell do
    @moduledoc false
    use GenServer

    def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

    def init(_opts) do
      {:ok, %{raw_value: 125000, tension_kgf: 0.0}}
    end

    def handle_call(:read, _from, state) do
      {:reply, state.tension_kgf, state}
    end

    def handle_call({:calibrate, zero, scale}, _from, state) do
      {:reply, :ok, %{state | raw_value: zero, tension_kgf: 0.0}}
    end

    def handle_call(:zero, _from, state) do
      {:reply, :ok, %{state | raw_value: 125000}}
    end

    def handle_call(:get_raw, _from, state) do
      {:reply, state.raw_value, state}
    end
  end

  defmodule MockLimitSwitch do
    @moduledoc false
    use GenServer

    def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

    def init(_opts) do
      {:ok, %{state: :released}}
    end

    def handle_call(:read_state, _from, state) do
      {:reply, state.state, state}
    end

    def handle_call(:check_pressed, _from, state) do
      {:reply, state.state == :pressed, state}
    end
  end
end
```

## test/support/fixtures.exs

```elixir
defmodule MyApp.Test.Fixtures do
  @moduledoc """
  Test fixtures.
  """

  def motor_state(opts \\ []) do
    %{
      current_position: Keyword.get(opts, :position, 0),
      target_position: Keyword.get(opts, :target, nil),
      state: Keyword.get(opts, :state, :idle),
      velocity: Keyword.get(opts, :velocity, 1000),
      enabled: Keyword.get(opts, :enabled, false)
    }
  end

  def load_cell_state(opts \\ []) do
    %{
      raw_value: Keyword.get(opts, :raw_value, 125000),
      tension_kgf: Keyword.get(opts, :tension, 0.0),
      zero_offset: Keyword.get(opts, :zero_offset, 125000),
      scale_factor: Keyword.get(opts, :scale_factor, 0.0035)
    }
  end

  def tension_state(opts \\ []) do
    %{
      target_kgf: Keyword.get(opts, :target, 20.0),
      current_kgf: Keyword.get(opts, :current, 0.0),
      pid_params: %{
        kp: Keyword.get(opts, :kp, 2.5),
        ki: Keyword.get(opts, :ki, 0.2),
        kd: Keyword.get(opts, :kd, 0.05)
      },
      control_state: Keyword.get(opts, :control_state, :idle),
      last_adjustment: DateTime.utc_now(),
      active_calibration_profile: Keyword.get(opts, :profile, "default")
    }
  end

  def calibration_profile(opts \\ []) do
    %{
      id: Keyword.get(opts, :id, "test_profile"),
      name: Keyword.get(opts, :name, "Test Profile"),
      zero_offset: Keyword.get(opts, :zero_offset, 125000),
      scale_factor: Keyword.get(opts, :scale_factor, 0.0035),
      motor_steps_per_kg: Keyword.get(opts, :steps_per_kg, 850),
      created_at: DateTime.utc_now(),
      verified_at: nil
    }
  end
end
```

## test/support/helpers.exs

```elixir
defmodule MyApp.Test.Helpers do
  @moduledoc """
  Test helper functions.
  """

  @doc """
  Wait for a condition to be true.
  """
  def wait_until(fun, timeout \\ 5000, interval \\ 100) do
    start = System.monotonic_time(:millisecond)

    do_wait_until(fun, start, timeout, interval)
  end

  defp do_wait_until(fun, start, timeout, interval) do
    if fun.() do
      :ok
    else
      if System.monotonic_time(:millisecond) - start > timeout do
        raise "Timeout waiting for condition"
      else
        Process.sleep(interval)
        do_wait_until(fun, start, timeout, interval)
      end
    end
  end

  @doc """
  Capture log messages.
  """
  def capture_logs(fun) do
    {:ok, pid} = StringIO.open("")
    original = Process.whereis(Logger)

    try do
      Logger.configure_backend(:console, device: pid)
      fun.()
      StringIO.close(pid)
    after
      Logger.configure_backend(:console, device: :standard_error)
    end
  end

  @doc """
  Start supervised process for testing.
  """
  def start_supervised_child({module, opts}) do
    start_supervised!(%{
      id: module,
      start: {module, :start_link, [opts]},
      restart: :temporary
    })
  end

  @doc """
  Get current test pid.
  """
  def test_pid, do: self()

  @doc """
  Assert state machine transition.
  """
  def assert_state_transition(from, to, state_machine) do
    assert MyApp.Control.Tension.StateMachine.valid_transition?(from, to),
      "Invalid state transition from #{from} to #{to}"
  end

  @doc """
  Refute state machine transition.
  """
  def refute_state_transition(from, to, state_machine) do
    refute MyApp.Control.Tension.StateMachine.valid_transition?(from, to),
      "Expected invalid state transition from #{from} to #{to}"
  end
end
```

## Hardware Tests

### test/my_app/hardware/motor_test.exs

```elixir
defmodule MyApp.Hardware.MotorTest do
  use ExUnit.Case
  use ExUnitProperties

  alias MyApp.Hardware.Motor
  alias MyApp.Hardware.Motor.Move
  alias MyApp.Hardware.Motor.Stop
  alias MyApp.Hardware.Motor.Home
  alias MyApp.Test.Fixtures
  alias MyApp.Test.HardwareMocks.MockMotor

  setup do
    {:ok, _} = start_supervised({MockMotor, []})
    :ok
  end

  describe "move/1" do
    test "moves motor to valid position" do
      assert {:ok, position} = Motor.move(100)
      assert is_integer(position)
      assert position == 100
    end

    test "rejects position too far" do
      assert {:error, :position_too_far} = Motor.move(200_000)
    end

    test "rejects invalid position type" do
      assert {:error, :invalid_position} = Motor.move("invalid")
    end

    property "moves to valid integer positions" do
      check all position <- integer(-50_000..50_000) do
        result = Motor.move(position)
        assert {:ok, ^position} = result
      end
    end
  end

  describe "stop/0" do
    test "stops motor" do
      Motor.move(100)
      assert :ok = Motor.stop()
    end
  end

  describe "home/0" do
    test "homes motor to zero" do
      Motor.move(1000)
      assert :ok = Motor.home()
      assert {:ok, 0} = Motor.get_position()
    end
  end

  describe "get_position/0" do
    test "returns current position" do
      Motor.move(100)
      assert {:ok, position} = Motor.get_position()
      assert is_integer(position)
    end
  end

  describe "set_speed/1" do
    test "sets motor speed" do
      assert :ok = Motor.set_speed(2000)
    end

    test "rejects invalid speed" do
      assert {:error, :invalid_speed} = Motor.set_speed(-100)
    end
  end
end
```

## Control Tests

### test/my_app/control/tension_test.exs

```elixir
defmodule MyApp.Control.TensionTest do
  use ExUnit.Case

  alias MyApp.Control.Tension
  alias MyApp.Control.Tension.SetTarget
  alias MyApp.Control.Tension.Adjust
  alias MyApp.Control.Tension.FeedJaws
  alias MyApp.Control.Tension.ReleaseTension
  alias MyApp.Test.Fixtures

  setup do
    state = Fixtures.tension_state()
    {:ok, state: state}
  end

  describe "set_target/1" do
    test "sets valid target tension" do
      assert {:ok, %Tension.Schema{target_kgf: 20.0}} = Tension.set_target(20.0)
    end

    test "rejects target below minimum" do
      assert {:error, :tension_too_low} = Tension.set_target(5.0)
    end

    test "rejects target above maximum" do
      assert {:error, :tension_too_high} = Tension.set_target(50.0)
    end

    test "rejects invalid target type" do
      assert {:error, :invalid_target} = Tension.set_target("invalid")
    end
  end

  describe "adjust/0" do
    test "performs PID adjustment" do
      Tension.set_target(20.0)
      assert {:ok, tension} = Tension.adjust()
      assert is_float(tension)
    end
  end

  describe "feed_jaws/0" do
    test "transitions to feeding_jaws state" do
      assert {:ok, state} = Tension.feed_jaws()
      assert state.control_state == :feeding_jaws
    end
  end

  describe "release_tension/0" do
    test "transitions to releasing_tension state" do
      Tension.set_target(20.0)
      Tension.feed_jaws()
      assert {:ok, state} = Tension.release_tension()
      assert state.control_state == :releasing_tension
    end
  end

  describe "get_current/0" do
    test "returns current tension" do
      Tension.set_target(20.0)
      assert {:ok, tension} = Tension.get_current()
      assert is_float(tension)
    end
  end

  describe "get_target/0" do
    test "returns target tension" do
      Tension.set_target(25.0)
      assert {:ok, 25.0} = Tension.get_target()
    end
  end

  describe "set_state/1" do
    test "sets valid state" do
      assert {:ok, state} = Tension.set_state(:applying_tension)
      assert state.control_state == :applying_tension
    end

    test "rejects invalid state" do
      assert {:error, :invalid_state} = Tension.set_state(:invalid_state)
    end
  end
end
```

## Integration Tests

### test/my_app/integration/tensioner_integration_test.exs

```elixir
defmodule MyApp.Integration.TensionerTest do
  use ExUnit.Case

  alias MyApp.Hardware.API, as: HardwareAPI
  alias MyApp.Control.API, as: ControlAPI
  alias MyApp.Test.HardwareMocks

  setup do
    {:ok, _} = start_supervised({HardwareMocks.MockMotor, []})
    {:ok, _} = start_supervised({HardwareMocks.MockLoadCell, []})
    {:ok, _} = start_supervised({HardwareMocks.MockLimitSwitch, []})
    :ok
  end

  describe "complete tensioner operation" do
    test "idle → feeding_jaws → waiting_for_string → applying_tension → holding → releasing_tension → idle" do
      # Initial state
      assert {:ok, :idle} = ControlAPI.get_state()

      # Feed jaws
      assert :ok = ControlAPI.feed_jaws()
      assert {:ok, :feeding_jaws} = ControlAPI.get_state()

      # Load string (simulated)
      assert :ok = HardwareAPI.stop()

      # Apply tension
      assert :ok = ControlAPI.set_target(20.0)
      assert :ok = ControlAPI.feed_jaws()
      assert {:ok, :applying_tension} = ControlAPI.get_state()

      # Hold tension
      Process.sleep(100)
      assert {:ok, :holding} = ControlAPI.get_state()

      # Release tension
      assert :ok = ControlAPI.release_tension()
      assert {:ok, :releasing_tension} = ControlAPI.get_state()

      # Return to idle
      Process.sleep(100)
      assert {:ok, :idle} = ControlAPI.get_state()
    end
  end
end
```

## Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/my_app/hardware/motor_test.exs

# Run with coverage
mix test --cover

# Run with verbose output
mix test --trace

# Run specific test
mix test test/my_app/hardware/motor_test.exs:17

# Run property-based tests
mix test --only property

# Run with specific seed for reproducibility
mix test --seed 12345
```

## Test Coverage Goals

- **Unit tests**: 95%+ coverage for each module
- **Integration tests**: Full workflow coverage
- **Property-based tests**: Critical functions (PID calculations, state transitions)
- **Mock coverage**: All hardware interactions mocked

## Usage

1. Copy test structure templates
2. Implement hardware mocks for your components
3. Create fixtures for your data structures
4. Write unit tests for each module
5. Write integration tests for workflows
6. Run tests before committing
7. Maintain high coverage
