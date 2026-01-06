# Nerves Firmware Development Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: NervesHub + Underjord + Curiosum (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Building firmware for embedded devices
- Deploying firmware to SD cards or over-the-air
- Cross-compiling for target boards
- Managing device fleets

❌ **DON'T use this file when**:
- Building regular web applications (use Phoenix/LiveView)
- Developing for desktop/server systems (use Elixir directly)
- Using Docker containers (use Nerves system)

**See also**:
- `genserver.md` - GenServer patterns (for device state)
- `otp_supervisor.md` - Supervisor strategies
- `concurrent_tasks.md` - Offloading patterns

---

## Pattern 1: Basic Firmware Build

**Problem**: Building firmware for target board

✅ **Solution**: Use standard mix tasks

```elixir
# Build firmware for current target
export MIX_TARGET=rpi4
mix firmware

# Or burn to SD card
mix firmware.burn

# Or create firmware image
mix firmware.image
```

**Reference**: NervesHub Quickstart tutorial (2025)

---

## Pattern 2: Cross-Compilation Targets

**Problem**: Building for different board architectures

✅ **Solution**: Set MIX_TARGET appropriately

| Target Board | MIX_TARGET | Architecture |
|---------------|-------------|-------------|
| Raspberry Pi 4 | `rpi4` | ARM64 |
| Raspberry Pi 3 | `rpi3` | ARMv7 |
| BeagleBone Black | `bbb` | ARMv7 |
| Generic x86_64 | `x86_64` | x86_64 |

✅ **Example**:
```elixir
# Set target for Raspberry Pi 4
export MIX_TARGET=rpi4

# Or cross-compile from Mac/Linux to ARM
export CC=arm-linux-gnueabihf-gcc
mix firmware
```

**Reference**: NervesHub supported targets documentation

---

## Pattern 3: Firmware Burning to SD Card

**Problem**: Flashing firmware to physical media

✅ **Solution**: Use mix firmware.burn with SUDO_ASKPASS

```elixir
# Burn firmware (will prompt for password)
export SUDO_ASKPASS=$(which ssh-askpass)
mix firmware.burn

# Burn specific image
mix firmware.burn my_firmware.fw

# Burn to specific SD card device
mix firmware.burn /dev/disk2
```

**Reference**: Underjord - Nerves project overview (2024)

---

## Pattern 4: A/B Partition Updates

**Problem**: Firmware updates can brick devices

✅ **Solution**: Use A/B partitions automatically

**Concept**:
- Partition A: Primary firmware (currently running)
- Partition B: New firmware (staged during update)
- Switch to B only if A boots successfully

**In firmware.exs**:
```elixir
config :nerves, :firmware,
  provisioning: :nerves_fw,
  burn_partition_prefix: "/dev/mmcblk0p"
  # A/B updates enabled by default with Nerves
```

**Reference**: NervesHub A/B update documentation

---

## Pattern 5: Over-the-Air (OTA) Updates

**Problem**: Updating firmware across deployed devices

✅ **Solution**: Use NervesHub for OTA

```elixir
# In config/runtime.exs
config :nerves, :firmware,
  provisioning: :nerves_hub  # Use NervesHub for OTA

# Or use custom NervesHub instance
# See: docs/nerves-hub-link/changelog.html (v2.9.0+)
```

**Reference**: NervesHub OTA documentation

---

## Pattern 6: Device Configuration at Runtime

**Problem**: Devices need different configs

✅ **Solution**: Use Nerves runtime configuration

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Use Nerves runtime for device config
      {Nerves.Runtime.KV, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Reference**: NervesHub documentation

---

## Pattern 7: Native NIFs (Native Implemented Functions)

**Problem**: Need hardware-specific C code

✅ **Solution**: Use NIFs in Elixir

```elixir
# C code in c_src/my_nif.c
defmodule MyNif do
  def my_function(_data) do
    :erlang.load_nif(:my_nif, :my_function, [_data])
  end
end

# Use in Elixir
defmodule MyApp.Hardware do
  def read_sensor() do
    MyNif.my_function(sensor_data)
  end
end
```

**Reference**: Nerves documentation on native NIFs

---

## Pattern 8: Custom Nerves System

**Problem**: Standard Nerves systems don't fit requirements

✅ **Solution**: Create custom system with Buildroot

```bash
# In mix.exs
defp deps do
  [{:nerves_system_br, path: "custom_system"}]
end

# Build custom system
export MIX_TARGET=rpi4
nerves_system_br create
```

**Reference**: Nerves custom systems documentation

---

## Pattern 9: Fleet Management

**Problem**: Managing multiple devices

✅ **Solution**: Use NervesHub or custom tools

```elixir
# NervesHub provides:
# - Firmware distribution
# - Device grouping
# - Configuration management
# - Health monitoring
# - Over-the-air updates

# Use NervesHub SDK or REST API
```

**Reference**: NervesHub documentation

---

## Pattern 10: Testing Nerves Applications

**Problem**: Hardware-specific testing challenges

✅ **Solution**: Use Nerves-specific test patterns

```elixir
# In test_helper.exs
ExUnit.start(exclude: [module: Nerves.Runtime.KV])

# Test with simulated hardware
defmodule HardwareTest do
  use ExUnit.Case

  import Mox

  setup do
    # Mock hardware interfaces
    {:ok, sensors} = mock(MyApp.Hardware.Sensors)
  end

  test "reads sensor data", %{sensors: sensors} do
    assert MyApp.Hardware.read_sensor(sensors) == {:ok, data}
  end
end
```

**Reference**: NervesHub testing documentation

---

## Testing Patterns for This File

### Unit Testing Nerves Applications

```elixir
defmodule MyApp.FirmwareTest do
  use ExUnit.Case

  test "firmware build succeeds" do
    Mix.Tasks.Firmware.run([])
    assert File.exists?("_build/rpi4/nerves/images/my_app.fw")
  end

  test "firmware image is created" do
    Mix.Tasks.FirmwareImage.run([])
    assert File.exists?("_build/rpi4/nerves/images/my_app.img")
  end
end
```

### Integration Testing

```elixir
defmodule MyApp.DeviceTest do
  use ExUnit.Case

  test "device boots firmware" do
    # Test requires actual hardware or simulation
    skip("Requires hardware")
  end
end
```

---

## References

**Primary Sources**:
- NervesHub - Quickstart and tutorials (2025)
- Underjord - "Unpacking Elixir - IoT & Embedded with Nerves" (2024)
- Curiosum - "IoT Doorstep Station: Nerves, Raspberry Pi & ESP32 Tutorial" (2025)
- Changelog - nerves_hub_link v2.9.0+ (2025)

**Related Patterns**:
- `genserver.md` - GenServer patterns (for device state)
- `otp_supervisor.md` - Supervisor strategies
- `concurrent_tasks.md` - Offloading patterns
