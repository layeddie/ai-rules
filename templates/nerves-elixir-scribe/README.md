# Nerves Template: elixir-scribe Pattern

**Purpose**: Nures embedded systems project template following elixir-scribe's self-documenting folder structure.

## Quick Start

```bash
# Create new Nerves project
mix nerves.new my_nerves_app

# Apply elixir-scribe pattern (manual, no generator available yet)
mkdir -p lib/my_nerves_app/domains/hardware
# Create actions manually
```

## Project Structure

### elixir-scribe DRA Pattern

```bash
lib/my_nerves_app/
└── domains/
    ├── hardware/
    │   ├── motor/
    │   │   ├── create.ex
    │   │   ├── update.ex
    │   │   ├── stop.ex
    │   │   ├── set_speed.ex
    │   │   ├── get_speed.ex
    │   │   └── api.ex
    │   ├── loadcell/
    │   │   ├── measure.ex
    │   │   ├── calibrate.ex
    │   │   └── api.ex
    │   ├── pid/
    │   │   ├── set_target.ex
    │   │   ├── read_actual.ex
    │   │   ├── compute_error.ex
    │   │   └── api.ex
    │   └── ui/
    │       ├── display/
    │       │   ├── show_text.ex
    │       │   ├── clear_text.ex
    │       │   └── api.ex
    └── api.ex
```

## Key Principles

1. **Hardware Abstraction**: Separate GenServers for hardware components
2. **Supervision Trees**: Proper OTP supervision for fault tolerance
3. **Domain Isolation**: Keep hardware, control, and UI separate
4. **SRP Enforcement**: One action per file
5. **Testability**: Mock hardware in tests

## Implementation Pattern

### Motor GenServer

```elixir
defmodule MyNervesApp.Domains.Hardware.Motor.Create do
  @moduledoc """
  Creates motor control task.
  """

  alias MyNervesApp.Domains.Hardware.MotorSupervisor

  @spec call(map()) :: {:ok, task_id()} | {:error, term()}
  def call(%{speed: speed, direction: direction}) do
    case MotorSupervisor.start_task(%{
      speed: speed,
      direction: direction
    }) do
      {:ok, task_id} ->
        :ok
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

### Domain API

```elixir
defmodule MyNervesApp.Domains.Hardware.Motor do
  @moduledoc """
  Motor domain API.
  """

  alias MyNervesApp.Domains.Hardware.Motor.{Create, Update, Stop, SetSpeed, GetSpeed}
  alias MyNervesApp.Domains.HardwareSupervisor

  @spec create(map()) :: {:ok, Motor.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs), do: Create.call(attrs)

  @spec update(integer(), map()) :: {:ok, Motor.t()} | {:error, Ecto.Changeset.t()}
  def update(id, attrs), do: Update.call(id, attrs)

  @spec stop(integer()) :: :ok | {:error, Ecto.Changeset.t()}
  def stop(task_id), do: Stop.call(task_id)

  @spec set_speed(integer(), integer()) :: {:ok | {:error, term()}
  def set_speed(task_id, speed), do: SetSpeed.call(task_id, speed)

  @spec get_speed(integer()) :: {:ok, integer()} | {:error, term()}
  def get_speed(task_id), do: GetSpeed.call(task_id)
end
```

## Hardware Abstraction

```elixir
# Mock hardware for testing
defmodule MyNervesApp.Domains.Hardware.MockMotor do
  @moduledoc """
  Mock motor for testing.
  """

  def create(attrs), do: {:ok, %{id: 1, speed: attrs.speed, direction: attrs.direction}}
  def read(_id), do: {:ok, %{speed: 100, direction: :stopped}}
  def update(_id, _attrs), do: :ok
  def delete(_id), do: :ok
end
```

## Testing

```elixir
# Unit test with mock hardware
defmodule MyNervesApp.Domains.Hardware.Motor.CreateTest do
  use ExUnit.Case, async: false
  alias MyNervesApp.Domains.Hardware.MockMotor

  test "creates motor task" do
    attrs = %{speed: 100, direction: :forward}
    assert {:ok, task_id} = MyNervesApp.Domains.Hardware.Motor.Create.call(attrs)
  end
end
```

## Related Documentation

- **Nerves templates**: `templates/nerves/README.md`
- **Hardware patterns**: `templates/nerves/hardware_genserver.md`
- **Supervision**: `templates/nerves/supervision_tree_dra_pattern.md`
- **Testing**: `templates/nerves/testing.md`
- **elixir-scribe skill**: `skills/elixir-scribe/SKILL.md`
- **Folder structure**: `patterns/elixir_scribe_folder_structure.md`

## Benefits of elixir-scribe for Nerves

1. **Self-documenting**: Folder structure reveals all hardware domains, resources, actions
2. **SRP Enforcement**: One action per file prevents complexity
3. **Explicit structure**: Clear boundaries in constrained embedded environment
4. **Easy navigation**: New team members understand codebase quickly
5. **No framework overhead**: Full control over code organization
