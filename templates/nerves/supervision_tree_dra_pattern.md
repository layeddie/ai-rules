# Nerves Supervision Tree & Domain Resource Action Template

## Supervision Tree Template

```elixir
# Application Supervisor
defmodule MyApp.Application do
  @moduledoc """
  Main application supervisor for MyApp.
  """
  use Application

  def start(_type, _args) do
    children = [
      # Hardware Layer
      MyApp.Hardware.Supervisor,
      
      # Control Layer
      MyApp.Control.Supervisor,
      
      # UI Layer
      MyApp.UI.Supervisor,
      
      # Logger
      MyApp.Logger.Logger
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Hardware Layer Supervisor
defmodule MyApp.Hardware.Supervisor do
  @moduledoc """
  Hardware layer supervisor.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {MyApp.Hardware.Motor, []},
      {MyApp.Hardware.LoadCell, []},
      {MyApp.Hardware.LimitSwitch, []}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end

# Control Layer Supervisor
defmodule MyApp.Control.Supervisor do
  @moduledoc """
  Control layer supervisor.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {MyApp.Control.Tension, []},
      {MyApp.Control.Calibration, []},
      {MyApp.Control.Safety, []}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end

# UI Layer Supervisor
defmodule MyApp.UI.Supervisor do
  @moduledoc """
  UI layer supervisor.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {MyApp.UI.Display, []},
      {MyApp.UI.ControlPanel, []},
      {MyApp.UI.WebServer, []}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
```

## Domain Resource Action Pattern Template

### Domain: Hardware

#### Resource: Motor

**Actions**: `move.ex`, `stop.ex`, `home.ex`, `feed_jaws.ex`, `release_tension.ex`, `get_position.ex`, `set_speed.ex`

**API Module** (`motor/api.ex`):

```elixir
defmodule MyApp.Hardware.Motor.API do
  @moduledoc """
  Public API for Motor resource.
  """

  alias MyApp.Hardware.Motor
  alias MyApp.Hardware.Motor.Move
  alias MyApp.Hardware.Motor.Stop
  alias MyApp.Hardware.Motor.Home
  alias MyApp.Hardware.Motor.FeedJaws
  alias MyApp.Hardware.Motor.ReleaseTension
  alias MyApp.Hardware.Motor.GetPosition
  alias MyApp.Hardware.Motor.SetSpeed

  @doc """
  Move motor to position.
  """
  def move(position) do
    with {:ok, _} <- Move.call(position) do
      {:ok, Motor.get_position()}
    end
  end

  @doc """
  Stop motor.
  """
  def stop, do: Stop.call()

  @doc """
  Home motor to limit switch.
  """
  def home, do: Home.call()

  @doc """
  Feed jaws forward (for stringer operation).
  """
  def feed_jaws, do: FeedJaws.call()

  @doc """
  Release tension and step back.
  """
  def release_tension, do: ReleaseTension.call()

  @doc """
  Get current motor position.
  """
  def get_position, do: GetPosition.call()

  @doc """
  Set motor speed.
  """
  def set_speed(speed), do: SetSpeed.call(speed)
end
```

**Action Module** (`motor/move.ex`):

```elixir
defmodule MyApp.Hardware.Motor.Move do
  @moduledoc """
  Move motor to position action.
  """

  alias MyApp.Hardware.Motor

  @type result :: {:ok, integer()} | {:error, atom()}

  @doc """
  Move motor to target position.
  """
  @spec call(integer()) :: result()
  def call(position) when is_integer(position) do
    with {:ok, current} <- Motor.get_position(),
         :ok <- validate_position(position, current) do
      GenServer.call(Motor, {:move, position})
    end
  end

  defp validate_position(target, current) when is_integer(target) and is_integer(current) do
    if abs(target - current) > 100_000 do
      {:error, :position_too_far}
    else
      :ok
    end
  end
end
```

**Resource GenServer** (`motor.ex`):

```elixir
defmodule MyApp.Hardware.Motor do
  @moduledoc """
  Motor control GenServer.
  """

  use GenServer
  require Logger

  defstruct [
    :current_position,
    :target_position,
    :state,
    :velocity,
    :enabled
  ]

  # Client API (delegated to API module)
  defdelegate move(position), to: MyApp.Hardware.Motor.API
  defdelegate stop(), to: MyApp.Hardware.Motor.API
  defdelegate home(), to: MyApp.Hardware.Motor.API
  defdelegate feed_jaws(), to: MyApp.Hardware.Motor.API
  defdelegate release_tension(), to: MyApp.Hardware.Motor.API
  defdelegate get_position(), to: MyApp.Hardware.Motor.API
  defdelegate set_speed(speed), to: MyApp.Hardware.Motor.API

  # Internal API (for action modules)
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # Server Callbacks
  @impl true
  def init(opts), do: {:ok, init_state(opts)}

  @impl true
  def handle_call({:move, position}, _from, state) do
    {:reply, :ok, %{state | target_position: position, state: :moving}}
  end

  @impl true
  def handle_call(:get_position, _from, state) do
    {:reply, state.current_position, state}
  end

  # Private helpers
  defp init_state(opts) do
    %__MODULE__{
      current_position: 0,
      target_position: nil,
      state: :idle,
      velocity: 1000,
      enabled: false
    }
  end
end
```

### Domain: Control

#### Resource: Tension

**State Machine**:

```elixir
defmodule MyApp.Control.Tension.StateMachine do
  @moduledoc """
  Tension control state machine.
  """

  @states [
    :idle,
    :feeding_jaws,
    :waiting_for_string,
    :applying_tension,
    :holding,
    :releasing_tension,
    :error,
    :emergency_stop
  ]

  @transitions [
    {:idle, :feeding_jaws},
    {:feeding_jaws, :waiting_for_string},
    {:waiting_for_string, :applying_tension},
    {:applying_tension, :holding},
    {:holding, :applying_tension},
    {:holding, :releasing_tension},
    {:releasing_tension, :idle},
    {:any, :error},
    {:any, :emergency_stop}
  ]

  def valid_transition?(from, to) do
    {from, to} in @transitions or (from == :error and to == :idle)
  end

  def valid_state?(state), do: state in @states
end
```

**Schema**:

```elixir
defmodule MyApp.Control.Tension.Schema do
  @moduledoc """
  Tension control schema.
  """

  @type t :: %__MODULE__{
    target_kgf: float(),
    current_kgf: float(),
    pid_params: map(),
    control_state: atom(),
    last_adjustment: DateTime.t(),
    active_calibration_profile: String.t()
  }

  defstruct [
    :target_kgf,
    :current_kgf,
    pid_params: %{},
    control_state: :idle,
    last_adjustment: DateTime.utc_now(),
    active_calibration_profile: "default"
  ]
end
```

**API Module** (`tension/api.ex`):

```elixir
defmodule MyApp.Control.Tension.API do
  @moduledoc """
  Public API for Tension resource.
  """

  alias MyApp.Control.Tension
  alias MyApp.Control.Tension.SetTarget
  alias MyApp.Control.Tension.Adjust
  alias MyApp.Control.Tension.FeedJaws
  alias MyApp.Control.Tension.ReleaseTension
  alias MyApp.Control.Tension.GetCurrent
  alias MyApp.Control.Tension.GetTarget
  alias MyApp.Control.Tension.SetState

  @doc """
  Set target tension (10-30 kgf).
  """
  def set_target(target_kgf) when is_float(target_kgf) do
    SetTarget.call(target_kgf)
  end

  @doc """
  PID-based tension adjustment.
  """
  def adjust do
    Adjust.call()
  end

  @doc """
  Feed jaws forward (stringer operation).
  """
  def feed_jaws do
    FeedJaws.call()
  end

  @doc """
  Release tension and step back.
  """
  def release_tension do
    ReleaseTension.call()
  end

  @doc """
  Get current tension.
  """
  def get_current do
    GetCurrent.call()
  end

  @doc """
  Get target tension.
  """
  def get_target do
    GetTarget.call()
  end

  @doc """
  Change control state.
  """
  def set_state(new_state) do
    SetState.call(new_state)
  end
end
```

## Domain API Template

**Hardware Domain API** (`hardware/api.ex`):

```elixir
defmodule MyApp.Hardware.API do
  @moduledoc """
  Unified hardware domain API.
  """

  alias MyApp.Hardware.Motor.API, as: MotorAPI
  alias MyApp.Hardware.LoadCell.API, as: LoadCellAPI
  alias MyApp.Hardware.LimitSwitch.API, as: LimitSwitchAPI

  # Motor operations
  defdelegate move(position), to: MotorAPI
  defdelegate stop(), to: MotorAPI
  defdelegate home(), to: MotorAPI
  defdelegate feed_jaws(), to: MotorAPI
  defdelegate release_tension(), to: MotorAPI
  defdelegate get_position(), to: MotorAPI

  # Load cell operations
  defdelegate read(), to: LoadCellAPI
  defdelegate calibrate(zero, scale), to: LoadCellAPI
  defdelegate zero(), to: LoadCellAPI

  # Limit switch operations
  defdelegate read_state(), to: LimitSwitchAPI
  defdelegate check_pressed(), to: LimitSwitchAPI

  # Unified error handling
  def handle_error(error) do
    Logger.error("Hardware error: #{inspect(error)}")
    {:error, :hardware_failure}
  end

  # Health monitoring
  def health_check do
    %{
      motor: MotorAPI.get_position(),
      load_cell: LoadCellAPI.read(),
      limit_switch: LimitSwitchAPI.read_state(),
      status: :ok
    }
  end
end
```

## Usage

1. Create domain folders: `hardware/`, `control/`, `ui/`
2. Create resource folders: `motor/`, `load_cell/`, `tension/`, etc.
3. Create action modules in each resource folder
4. Create API module for each resource
5. Create domain-level API module
6. Add resources to appropriate supervisor
7. Follow the pattern: API → Action → GenServer
