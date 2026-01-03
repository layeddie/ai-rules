# Nerves Project Template

## Project Structure

```
my_nerves_app/
├── mix.exs
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   ├── target.exs
│   ├── nerves.exs
│   ├── hardware.exs
│   └── pid.exs
├── lib/
│   ├── my_app.ex
│   ├── my_app/
│   │   ├── application.ex
│   │   ├── hardware/
│   │   ├── control/
│   │   ├── ui/
│   │   └── config.ex
├── test/
├── rootfs_overlay/
│   └── etc/
│       └── nerves_config.sh
├── firmware/
│   └── target/
├── .formatter.exs
├── .credo.exs
├── .dialyzer_ignore.exs
└── README.md
```

## mix.exs Template

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  @app :my_app
  @version "0.1.0"
  @all_targets [:rpi0, :rpi, :rpi3, :rpi4, :bbb, :x86_64]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.14",
      archives: [nerves_bootstrap: "~> 1.13"],
      deps_path: "../../deps",
      build_path: "../../_build/#{Mix.env()}/#{@app}",
      config_path: "../../config/config.exs",
      lockfile: "../../mix.lock",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  def application do
    [
      mod: {MyApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nerves, "~> 1.10", runtime: false},
      {:shoehorn, "~> 0.9"},
      {:ring_logger, "~> 0.8"},
      {:toolshed, "~> 0.3"},
      
      # Dependencies for specific targets
      {:nerves_system_rpi, "~> 1.21", runtime: false, targets: :rpi},
      {:nerves_system_rpi0, "~> 1.21", runtime: false, targets: :rpi0},
      {:nerves_system_rpi3, "~> 1.21", runtime: false, targets: :rpi3},
      {:nerves_system_rpi4, "~> 1.21", runtime: false, targets: :rpi4},
      
      # Add hardware-specific dependencies here
      # {:circuits_gpio, "~> 1.2"},
      # {:circuits_i2c, "~> 2.0"},
      # {:circuits_spi, "~> 1.3"},
      
      # Development and test dependencies
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    ]
  end

  def release do
    [
      overwrite: true,
      include_erts: &Nerves.Release.erts/0,
      init: &Nerves.Release.init/0,
      pre_start: "firmware/mount.exs"
    ]
  end
end
```

## config/nerves.exs Template

```elixir
# Nerves configuration
import Config

if Mix.target() != :host do
  import_config "target.exs"
end

# Shoehorn for boot order
config :shoehoe, init: [:nerves_runtime, :nerves_pack]
config :shoehoe, overlap: [nerves_runtime: false]

# RingLogger backend
config :logger, backends: [RingLogger]

# NervesTime for time sync
config :nerves_time, servers: ["pool.ntp.org"]

# Config for Erlang VM
config :vm, args: ["-B", "Elixir"]

# Nerves Runtime
config :nerves_runtime,
  kernel_modules: [],
  nvram_partitions: []

# Nerves Pack (WiFi/SSH)
config :nerves_pack,
  ssid: "MyWiFi",
  psk: "password",
  regulatory_domain: "US"
```

## config/target.exs Template

```elixir
import Config

# Target-specific configuration

# Erlang VM parameters
config :vm,
  args: ["-B", "Elixir", "-mode", "embedded"]

# Erlang distribution
config :kernel, inet_dist_use_interface: :udhcp

# Mnesia
config :mnesia, dir: "/mnt/root/data/mnesia"

# File system
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Disable system logging
config :logger, level: :info
```

## config/hardware.exs Template

```elixir
import Config

# Hardware pin mappings and configuration

# GPIO pins
config :my_app, :gpio,
  motor_enable: 17,
  motor_step: 18,
  motor_dir: 27,
  limit_switch: 22,
  pull_button: 5,
  release_button: 6

# I2C configuration
config :my_app, :i2c,
  bus_name: "i2c-1",
  display_address: 0x3C

# SPI configuration
config :my_app, :spi,
  bus_name: "spidev0.0",
  chip_select: 0,
  mode: 0,
  bits_per_word: 8,
  speed_hz: 10_000_000

# PWM configuration
config :my_app, :pwm,
  motor_pwm_chip: "pwmchip0",
  motor_pwm_channel: 0
```

## config/pid.exs Template

```elixir
import Config

# PID Controller parameters

# Motor control PID
config :my_app, :motor_pid,
  kp: 1.0,
  ki: 0.1,
  kd: 0.01,
  sample_interval_ms: 50,
  output_min: -1000,
  output_max: 1000

# Tension control PID
config :my_app, :tension_pid,
  kp: 2.5,
  ki: 0.2,
  kd: 0.05,
  sample_interval_ms: 100,
  output_min: -500,
  output_max: 500
```

## lib/my_app/application.ex Template

```elixir
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
```

## Usage

1. Create new Nerves project:
```bash
mix nerves.new my_app --target rpi0
cd my_app
```

2. Replace default files with templates

3. Configure hardware pins in `config/hardware.exs`

4. Configure PID parameters in `config/pid.exs`

5. Add hardware-specific dependencies to `mix.exs`

6. Follow Domain Resource Action pattern for implementation
