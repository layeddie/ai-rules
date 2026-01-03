# Nerves Templates

This directory contains templates and patterns for building Nerves applications following best practices and the Domain Resource Action pattern.

## Templates

### 1. [project_setup.md](./project_setup.md)
Complete Nerves project structure and configuration templates:
- Project structure
- `mix.exs` template
- `config/nerves.exs`, `config/target.exs`, `config/hardware.exs`, `config/pid.exs`
- `application.ex` template

**When to use**: Creating a new Nerves project from scratch

### 2. [hardware_genserver.md](./hardware_genserver.md)
Hardware GenServer patterns for common hardware components:
- Motor GenServer (stepper motor control)
- LoadCell GenServer (HX711 ADC interface)
- LimitSwitch GenServer (GPIO monitoring)
- Hardware Supervisor template

**When to use**: Implementing hardware interfaces as GenServers

### 3. [supervision_tree_dra_pattern.md](./supervision_tree_dra_pattern.md)
Supervision tree and Domain Resource Action (DRA) pattern:
- Complete supervision tree (Application → Hardware/Control/UI supervisors)
- Domain Resource Action pattern templates
- Resource schemas and API modules
- State machine pattern
- Domain API modules

**When to use**: Organizing your application with DRA pattern and building supervision tree

### 4. [deployment_config.md](./deployment_config.md)
Deployment and configuration templates:
- `config/nerves.exs`, `config/target.exs`, `config/hardware.exs`, `config/pid.exs`
- `rootfs_overlay/etc/nerves_config.sh`
- Firmware burn and update scripts
- Runtime configuration
- Persistent configuration with Nerves KV

**When to use**: Setting up deployment, configuration management, and firmware distribution

### 5. [testing.md](./testing.md)
Comprehensive testing templates:
- Test structure
- Hardware mocks
- Test fixtures
- Helper functions
- Unit tests (Motor, LoadCell, LimitSwitch)
- Control tests (Tension, Calibration)
- Integration tests

**When to use**: Setting up test suite and writing tests for Nerves applications

## Pattern: Domain Resource Action (DRA)

The DRA pattern organizes business logic into:

- **Domains**: High-level business areas (e.g., Hardware, Control, UI)
- **Resources**: Entities within a domain (e.g., Motor, Tension, Display)
- **Actions**: Operations on a resource (e.g., move, set_target, show_tension)

### Structure

```
lib/my_app/
├── hardware/          # Domain
│   ├── motor.ex       # Resource (GenServer)
│   ├── motor/         # Resource actions
│   │   ├── move.ex
│   │   ├── stop.ex
│   │   ├── get_position.ex
│   │   └── api.ex    # Resource API
│   └── api.ex        # Domain API
├── control/           # Domain
│   ├── tension.ex    # Resource (GenServer)
│   ├── tension/      # Resource actions
│   │   ├── set_target.ex
│   │   ├── adjust.ex
│   │   └── api.ex    # Resource API
│   └── api.ex        # Domain API
└── ui/               # Domain
    ├── display.ex    # Resource (GenServer)
    └── api.ex        # Domain API
```

### Access Pattern

```elixir
# Use domain API for operations
MyApp.Hardware.API.move(100)
MyApp.Control.API.set_target(20.0)
MyApp.UI.API.show_tension()

# Domain API delegates to resource actions
# Resource actions implement business logic
# Resource GenServer manages state
```

## Quick Start

### 1. Create New Project

```bash
mix nerves.new my_app --target rpi0
cd my_app
```

### 2. Apply Templates

Replace default files with templates from `project_setup.md`

### 3. Configure Hardware

Update pin mappings in `config/hardware.exs`

### 4. Implement Hardware Layer

Use `hardware_genserver.md` templates for:
- Motor (stepper motor)
- LoadCell (sensors/ADC)
- LimitSwitch (GPIO monitoring)

### 5. Build Supervision Tree

Use `supervision_tree_dra_pattern.md` to organize:
- Hardware Supervisor
- Control Supervisor
- UI Supervisor

### 6. Set Up Testing

Use `testing.md` templates:
- Hardware mocks
- Test fixtures
- Unit tests
- Integration tests

### 7. Configure Deployment

Use `deployment_config.md` for:
- Firmware configuration
- RootFS overlay
- Deployment scripts

### 8. Build and Deploy

```bash
export MIX_TARGET=rpi0
mix deps.get
mix firmware
sudo fwup -a -i _build/rpi0_dev/nerves/images/my_app.fw -t /dev/sdX
```

## Key Principles

1. **Hardware Abstraction**: Separate hardware logic from business logic
2. **Supervision Trees**: Proper OTP supervision for fault tolerance
3. **Domain Isolation**: Keep domains independent via API modules
4. **Testability**: Mock hardware in tests, use property-based testing
5. **Configuration Management**: Externalize hardware configuration
6. **Safety First**: Implement safety limits and emergency stops
7. **State Machines**: Use explicit states for complex workflows

## Related Documentation

- [Nerves Official Documentation](https://hexdocs.pm/nerves)
- [Nerves Getting Started Guide](https://hexdocs.pm/nerves/getting-started.html)
- [Nerves Runtime](https://hexdocs.pm/nerves_runtime)
- [Circuits](https://hexdocs.pm/circuits)
- [Nerves Pack](https://hexdocs.pm/nerves_pack)

## Example Applications

- **Tensioner**: Electronic string tensioner (see `tensioner/ARCHITECTURE_PLAN.md`)
  - Motor control with TMC2130
  - Load cell with HX711
  - SSD1306 OLED display
  - PID control loops
  - State machine for workflow

## Best Practices

1. **TDD First**: Write tests before implementing logic
2. **Mock Hardware**: Always mock hardware in tests
3. **Separate Concerns**: Keep hardware, control, and UI separate
4. **Use GenServers**: Manage state with proper GenServers
5. **API Modules**: Provide clean public APIs via API modules
6. **Error Handling**: Proper error handling at all layers
7. **Logging**: Use RingLogger for device logging
8. **Configuration**: Externalize all hardware configuration
9. **Safety**: Implement limits and emergency stops
10. **Documentation**: Document all public functions with `@moduledoc` and `@doc`

## Troubleshooting

### Build Issues
```bash
# Clean and rebuild
rm -rf _build
mix firmware
```

### Target Issues
```bash
# Verify target
export MIX_TARGET=rpi0
echo $MIX_TARGET
```

### Dependency Issues
```bash
# Clean deps
rm -rf deps
mix deps.get
```

### Hardware Issues
- Check pin mappings in `config/hardware.exs`
- Verify hardware connections
- Check logs with `ringbird` on target

## Contributing

To contribute new templates or improvements:

1. Create new template file following existing patterns
2. Add to this README with description
3. Include usage examples
4. Test templates on real hardware when possible
