# Nerves Hardware GenServer Template

## Pattern Overview

Use this template for implementing hardware interfaces as GenServers in Nerves applications.

## Motor GenServer Template

```elixir
defmodule MyApp.Hardware.Motor do
  @moduledoc """
  Motor control GenServer using stepper motor driver.
  """
  
  use GenServer
  require Logger

  @step_angle 1.8
  @steps_per_rev trunc(360 / @step_angle)
  @lead_mm 2.54

  defstruct [
    :current_position,
    :target_position,
    :state,
    :velocity,
    :enabled
  ]

  @type t :: %__MODULE__{
    current_position: integer(),
    target_position: integer() | nil,
    state: :idle | :moving | :error,
    velocity: integer(),
    enabled: boolean()
  }

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def move(position) when is_integer(position) do
    GenServer.call(__MODULE__, {:move, position})
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def home do
    GenServer.call(__MODULE__, :home)
  end

  def set_speed(speed) when is_integer(speed) and speed > 0 do
    GenServer.call(__MODULE__, {:set_speed, speed})
  end

  def get_position do
    GenServer.call(__MODULE__, :get_position)
  end

  def enable do
    GenServer.call(__MODULE__, :enable)
  end

  def disable do
    GenServer.call(__MODULE__, :disable)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    {:ok, init_hardware(opts), {:continue, :initialized}}
  end

  @impl true
  def handle_continue(:initialized, state) do
    Logger.info("Motor initialized")
    {:noreply, state}
  end

  @impl true
  def handle_call({:move, position}, _from, state) do
    steps = calculate_steps(state.current_position, position)
    {:reply, :ok, %{state | target_position: position, state: :moving}}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:reply, :ok, %{state | state: :idle}}
  end

  @impl true
  def handle_call(:home, _from, state) do
    {:reply, :ok, home_motor(state)}
  end

  @impl true
  def handle_call({:set_speed, speed}, _from, state) do
    {:reply, :ok, %{state | velocity: speed}}
  end

  @impl true
  def handle_call(:get_position, _from, state) do
    {:reply, state.current_position, state}
  end

  @impl true
  def handle_call(:enable, _from, state) do
    enable_motor()
    {:reply, :ok, %{state | enabled: true}}
  end

  @impl true
  def handle_call(:disable, _from, state) do
    disable_motor()
    {:reply, :ok, %{state | enabled: false}}
  end

  # Hardware Abstraction Layer

  defp init_hardware(opts) do
    bus_name = Keyword.get(opts, :spi_bus, "spidev0.0")
    
    {:ok, spi_ref} = Circuits.SPI.open(bus_name, mode: 0)
    
    %__MODULE__{
      current_position: 0,
      target_position: nil,
      state: :idle,
      velocity: 1000,
      enabled: false
    }
  end

  defp enable_motor do
    gpio_config = Application.get_env(:my_app, :gpio)
    enable_pin = Keyword.fetch!(gpio_config, :motor_enable)
    
    {:ok, gpio} = Circuits.GPIO.open(enable_pin, :output)
    Circuits.GPIO.write(gpio, 1)
    
    Logger.debug("Motor enabled")
  end

  defp disable_motor do
    gpio_config = Application.get_env(:my_app, :gpio)
    enable_pin = Keyword.fetch!(gpio_config, :motor_enable)
    
    {:ok, gpio} = Circuits.GPIO.open(enable_pin, :output)
    Circuits.GPIO.write(gpio, 0)
    
    Logger.debug("Motor disabled")
  end

  defp step_motor(direction, count) do
    gpio_config = Application.get_env(:my_app, :gpio)
    step_pin = Keyword.fetch!(gpio_config, :motor_step)
    dir_pin = Keyword.fetch!(gpio_config, :motor_dir)
    
    {:ok, step_gpio} = Circuits.GPIO.open(step_pin, :output)
    {:ok, dir_gpio} = Circuits.GPIO.open(dir_pin, :output)
    
    Circuits.GPIO.write(dir_gpio, if(direction == :forward, do: 1, else: 0))
    
    for _ <- 1..count do
      Circuits.GPIO.write(step_gpio, 1)
      Process.sleep(1)
      Circuits.GPIO.write(step_gpio, 0)
      Process.sleep(1)
    end
  end

  defp home_motor(state) do
    gpio_config = Application.get_env(:my_app, :gpio)
    limit_pin = Keyword.fetch!(gpio_config, :limit_switch)
    
    {:ok, limit_gpio} = Circuits.GPIO.open(limit_pin, :input)
    
    step_motor(:reverse, 100_000)
    
    %{
      state
      | current_position: 0,
        target_position: nil,
        state: :idle
    }
  end

  defp calculate_steps(current, target) do
    (target - current) * @steps_per_rev
  end
end
```

## LoadCell GenServer Template

```elixir
defmodule MyApp.Hardware.LoadCell do
  @moduledoc """
  Load cell interface using HX711 ADC.
  """
  
  use GenServer
  require Logger

  @sample_rate 100

  defstruct [
    :raw_value,
    :tension_kgf,
    :zero_offset,
    :scale_factor,
    :last_read_time
  ]

  @type t :: %__MODULE__{
    raw_value: integer(),
    tension_kgf: float(),
    zero_offset: integer(),
    scale_factor: float(),
    last_read_time: DateTime.t()
  }

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def read do
    GenServer.call(__MODULE__, :read)
  end

  def calibrate(zero_offset, scale_factor) do
    GenServer.call(__MODULE__, {:calibrate, zero_offset, scale_factor})
  end

  def zero do
    GenServer.call(__MODULE__, :zero)
  end

  def get_raw do
    GenServer.call(__MODULE__, :get_raw)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    {:ok, init_hardware(opts), {:continue, :start_sampling}}
  end

  @impl true
  def handle_continue(:start_sampling, state) do
    schedule_read()
    {:noreply, state}
  end

  @impl true
  def handle_info(:read, state) do
    {:ok, raw_value} = read_adc()
    tension_kgf = calculate_tension(raw_value, state)
    
    new_state = %{state | raw_value: raw_value, tension_kgf: tension_kgf}
    schedule_read()
    
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:read, _from, state) do
    {:reply, state.tension_kgf, state}
  end

  @impl true
  def handle_call({:calibrate, zero_offset, scale_factor}, _from, state) do
    {:reply, :ok, %{state | zero_offset: zero_offset, scale_factor: scale_factor}}
  end

  @impl true
  def handle_call(:zero, _from, state) do
    {:ok, raw_value} = read_adc()
    {:reply, :ok, %{state | zero_offset: raw_value}}
  end

  @impl true
  def handle_call(:get_raw, _from, state) do
    {:reply, state.raw_value, state}
  end

  # Hardware Abstraction Layer

  defp init_hardware(opts) do
    bus_name = Keyword.get(opts, :spi_bus, "spidev0.1")
    clock_pin = Keyword.get(opts, :clock_pin, 11)
    
    {:ok, _} = Circuits.GPIO.open(clock_pin, :output)
    Circuits.GPIO.write(_clock_gpio, 1)
    
    %__MODULE__{
      raw_value: 0,
      tension_kgf: 0.0,
      zero_offset: 125_000,
      scale_factor: 0.0035,
      last_read_time: DateTime.utc_now()
    }
  end

  defp read_adc do
    spi_config = Application.get_env(:my_app, :spi)
    bus_name = Keyword.fetch!(spi_config, :bus_name)
    
    {:ok, spi} = Circuits.SPI.open(bus_name)
    
    {:ok, data} = Circuits.SPI.transfer(spi, <<0::24>>)
    <<value::signed-big-integer-24>> = data
    
    {:ok, value}
  end

  defp calculate_tension(raw_value, state) do
    calibrated = (raw_value - state.zero_offset) * state.scale_factor
    calibrated |> clamp(0.0, 40.0) |> Float.round(3)
  end

  defp schedule_read do
    interval_ms = trunc(1000 / @sample_rate)
    Process.send_after(self(), :read, interval_ms)
  end

  defp clamp(value, min, max) do
    value
    |> max(min)
    |> min(max)
  end
end
```

## LimitSwitch GenServer Template

```elixir
defmodule MyApp.Hardware.LimitSwitch do
  @moduledoc """
  Limit switch monitoring GenServer.
  """
  
  use GenServer
  require Logger

  defstruct [
    :current_state,
    :subscribers,
    :gpio_ref
  ]

  @type t :: %__MODULE__{
    current_state: :pressed | :released,
    subscribers: [pid()],
    gpio_ref: reference()
  }

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def read_state do
    GenServer.call(__MODULE__, :read_state)
  end

  def check_pressed do
    GenServer.call(__MODULE__, :check_pressed)
  end

  def subscribe do
    GenServer.call(__MODULE__, :subscribe)
  end

  def unsubscribe do
    GenServer.call(__MODULE__, :unsubscribe)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    {:ok, init_hardware(opts), {:continue, :start_monitoring}}
  end

  @impl true
  def handle_continue(:start_monitoring, state) do
    schedule_check()
    {:noreply, state}
  end

  @impl true
  def handle_info(:check, state) do
    current_value = read_gpio(state.gpio_ref)
    new_state = if current_value == 0, do: :pressed, else: :released
    
    if new_state != state.current_state do
      notify_subscribers(state.subscribers, new_state)
    end
    
    schedule_check()
    {:noreply, %{state | current_state: new_state}}
  end

  @impl true
  def handle_call(:read_state, _from, state) do
    {:reply, state.current_state, state}
  end

  @impl true
  def handle_call(:check_pressed, _from, state) do
    {:reply, state.current_state == :pressed, state}
  end

  @impl true
  def handle_call(:subscribe, {pid, _ref}, state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | subscribers: [pid | state.subscribers]}}
  end

  @impl true
  def handle_call(:unsubscribe, {pid, _ref}, state) do
    {:reply, :ok, %{state | subscribers: List.delete(state.subscribers, pid)}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | subscribers: List.delete(state.subscribers, pid)}}
  end

  # Hardware Abstraction Layer

  defp init_hardware(opts) do
    gpio_config = Application.get_env(:my_app, :gpio)
    pin = Keyword.get(opts, :pin, Keyword.fetch!(gpio_config, :limit_switch))
    
    {:ok, gpio} = Circuits.GPIO.open(pin, :input, pull_mode: :pullup)
    
    %__MODULE__{
      current_state: :released,
      subscribers: [],
      gpio_ref: gpio
    }
  end

  defp read_gpio(gpio) do
    Circuits.GPIO.read(gpio)
  end

  defp schedule_check do
    Process.send_after(self(), :check, 10)
  end

  defp notify_subscribers(subscribers, new_state) do
    for subscriber <- subscribers do
      send(subscriber, {:limit_switch, new_state})
    end
  end
end
```

## Hardware Supervisor Template

```elixir
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
```

## Usage

1. Copy the relevant GenServer template
2. Update pin configurations in `config/hardware.exs`
3. Implement hardware-specific SPI/I2C/GPIO logic
4. Add to hardware supervisor
5. Write tests using hardware mocks
