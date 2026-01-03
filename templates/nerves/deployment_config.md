# Nerves Deployment & Configuration Template

## Nerves Configuration Files

### config/nerves.exs

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

# SSH Keys
config :nerves_ssh,
  authorized_keys: [
    File.read!(Path.expand([~c"~/.ssh", ~c"id_rsa.pub"]))
  ]
```

### config/target.exs

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

# Nerves Runtime keyring storage
config :nerves_runtime,
  kv_backend: Nerves.Runtime.KVBackend.Inert
```

### config/hardware.exs

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
  release_button: 6,
  motor_fault: 4,
  display_reset: 16

# I2C configuration
config :my_app, :i2c,
  bus_name: "i2c-1",
  display_address: 0x3C,
  adc_address: 0x48

# SPI configuration
config :my_app, :spi,
  bus_name: "spidev0.0",
  chip_select: 0,
  mode: 0,
  bits_per_word: 8,
  speed_hz: 10_000_000

# UART configuration
config :my_app, :uart,
  device_name: "ttyS0",
  speed: 115200

# PWM configuration
config :my_app, :pwm,
  motor_pwm_chip: "pwmchip0",
  motor_pwm_channel: 0
```

### config/pid.exs

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

## rootfs_overlay Configuration

### rootfs_overlay/etc/nerves_config.sh

```bash
#!/bin/sh

# Nerves firmware configuration script
# This script runs on the target device after firmware is installed

# Set timezone
echo "America/Los_Angeles" > /etc/TZ

# Configure hostname
hostname myapp-device

# Mount data partition
mkdir -p /mnt/root/data
mount /dev/mmcblk0p3 /mnt/root/data 2>/dev/null || true

# Start SSH on boot
# SSH is started by Nerves SSH automatically

# Configure WiFi (if using Nerves Pack)
# WiFi configuration is done via Nerves Pack

# Set up persistent logging
mkdir -p /mnt/root/data/logs
touch /mnt/root/data/logs/app.log

echo "Nerves configuration complete"
```

### rootfs_overlay/etc/ssh/sshd_config

```bash
# SSH configuration for Nerves

Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile /data/ssh/authorized_keys

# Nerves SSH uses this file
```

## Deployment Scripts

### firmware/mount.exs

```elixir
# Firmware mount script for Nerves
# This script is executed before the application starts

# Mount application data partition
File.mkdir_p!("/mnt/root/data")

# Ensure persistent directories exist
File.mkdir_p!("/mnt/root/data/mnesia")
File.mkdir_p!("/mnt/root/data/logs")
File.mkdir_p!("/mnt/root/data/kv")

IO.puts("Firmware mount complete")
```

### scripts/burn_firmware.sh

```bash
#!/bin/bash

# Burn Nerves firmware to SD card

set -e

# Configuration
FIRMWARE_PATH="_build/rpi0_dev/nerves/images/my_app.fw"
SD_CARD_DEVICE="/dev/sdX"

# Check if firmware exists
if [ ! -f "$FIRMWARE_PATH" ]; then
    echo "Error: Firmware not found at $FIRMWARE_PATH"
    echo "Run: mix firmware"
    exit 1
fi

# Check if device exists
if [ ! -b "$SD_CARD_DEVICE" ]; then
    echo "Error: SD card device not found: $SD_CARD_DEVICE"
    exit 1
fi

# Confirm
echo "This will overwrite all data on $SD_CARD_DEVICE"
read -p "Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted"
    exit 0
fi

# Unmount if mounted
sudo umount ${SD_CARD_DEVICE}* 2>/dev/null || true

# Burn firmware
echo "Burning firmware to SD card..."
sudo fwup -a -i "$FIRMWARE_PATH" -t "$SD_CARD_DEVICE"

echo "Firmware burned successfully"
echo "Remove SD card and insert into device"
```

### scripts/update_firmware.sh

```bash
#!/bin/bash

# Update running Nerves firmware over the network

set -e

# Configuration
DEVICE_IP="192.168.1.100"
FIRMWARE_PATH="_build/rpi0_dev/nerves/images/my_app.fw"

# Check if firmware exists
if [ ! -f "$FIRMWARE_PATH" ]; then
    echo "Error: Firmware not found at $FIRMWARE_PATH"
    echo "Run: mix firmware"
    exit 1
fi

# Push firmware to device
echo "Pushing firmware to device..."
ssh root@$DEVICE_IP "mkdir -p /tmp/firmware"
scp "$FIRMWARE_PATH" root@$DEVICE_IP:/tmp/firmware/fw_update.fw

# Apply firmware update
echo "Applying firmware update..."
ssh root@$DEVICE_IP "fwup -a -i /tmp/firmware/fw_update.fw -t /dev/mmcblk0 && reboot"

echo "Firmware update complete. Device is rebooting."
```

## mix.exs Release Configuration

```elixir
def release do
  [
    overwrite: true,
    include_erts: &Nerves.Release.erts/0,
    init: &Nerves.Release.init/0,
    pre_start: "firmware/mount.exs",
    strip_beams: Mix.env() == :prod,
    steps: [&Nerves.Release.init/0, :assemble, &Nerves.Release.copy_firmware/1]
  ]
end
```

## Build and Deployment Commands

### Build Firmware

```bash
# Set target
export MIX_TARGET=rpi0

# Get dependencies
mix deps.get

# Build firmware
mix firmware

# Burn to SD card
sudo fwup -a -i _build/rpi0_dev/nerves/images/my_app.fw -t /dev/sdX

# Or use burn script
./scripts/burn_firmware.sh
```

### Update Firmware Over Network

```bash
# Build firmware
mix firmware

# Update running device
./scripts/update_firmware.sh

# Or manually
scp _build/rpi0_dev/nerves/images/my_app.fw root@device-ip:/tmp/
ssh root@device-ip "fwup -a -i /tmp/my_app.fw -t /dev/mmcblk0 && reboot"
```

### Debug on Target

```bash
# Connect to device over SSH
ssh root@device-ip

# View application logs
ringbird

# View system logs
journalctl -u nerves_init_ssh -f

# Run IEx on device
iex

# Check Nerves runtime info
cmd("fwup -e -i /dev/mmcblk0p4 -d")
```

## Configuration Management

### Runtime Configuration

```elixir
# In your application
defmodule MyApp.Config do
  @moduledoc """
  Runtime configuration loader.
  """

  def load_config do
    %{
      gpio: Application.get_env(:my_app, :gpio),
      i2c: Application.get_env(:my_app, :i2c),
      spi: Application.get_env(:my_app, :spi),
      motor_pid: Application.get_env(:my_app, :motor_pid),
      tension_pid: Application.get_env(:my_app, :tension_pid)
    }
  end

  def get_pin(key) do
    config = Application.get_env(:my_app, :gpio)
    Keyword.fetch!(config, key)
  end

  def get_i2c_bus do
    config = Application.get_env(:my_app, :i2c)
    Keyword.fetch!(config, :bus_name)
  end
end
```

### Persistent Configuration with Nerves KV

```elixir
defmodule MyApp.ConfigStore do
  @moduledoc """
  Persistent configuration storage using Nerves KV.
  """

  @prefix "my_app_config"

  def put(key, value) do
    kv_key = "#{@prefix}_#{key}"
    Nerves.Runtime.KV.put(kv_key, Jason.encode!(value))
  end

  def get(key, default \\ nil) do
    kv_key = "#{@prefix}_#{key}"
    case Nerves.Runtime.KV.get(kv_key) do
      nil -> default
      value -> Jason.decode!(value)
    end
  end

  def delete(key) do
    kv_key = "#{@prefix}_#{key}"
    Nerves.Runtime.KV.put(kv_key, nil)
  end
end
```

## Usage

1. Copy configuration templates to your project
2. Update pin mappings in `config/hardware.exs`
3. Update PID parameters in `config/pid.exs`
4. Update `rootfs_overlay/etc/nerves_config.sh` as needed
5. Use deployment scripts for burning and updating firmware
6. Use ConfigStore for persistent configuration
