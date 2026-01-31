# Elixir Patterns Directory

**Purpose**: Curated collection of ~600-800 Elixir patterns for quick reference and efficient development.

🚀 **Quick Start**: Use [PATTERN_INDEX.md](./PATTERN_INDEX.md) for fast pattern lookup (2K tokens, <5 seconds)!

## Quick Start: Finding Right Pattern

1. **I know my problem** (e.g., "Need to test a GenServer")
   → Check `exunit_testing.md` section "GenServer Testing"

2. **I know my framework/area** (e.g., "Phoenix LiveView data loading")
   → Check `liveview.md` section "Anti-Patterns"

3. **I want performance guidance** (e.g., "Caching strategy")
   → Check `ets_performance.md` decision matrix

4. **I need design patterns** (e.g., "Supervisor strategy")
   → Check `otp_supervisor.md` strategy selection guide

## Pattern Categories

| Category | Files | When to Use |
|-----------|-------|--------------|
| **State Management** | genserver.md, ets_performance.md, concurrent_tasks.md | GenServer, caching, concurrency |
| **Web Patterns** | liveview.md, phoenix_controllers.md | LiveView, controllers, uploads |
| **Ash Framework** | ash_resources.md, migration_strategies.md | Resources, migrations, policies |
| **OTP/Supervision** | otp_supervisor.md, exunit_testing.md (GenServer tests) | Supervisors, process trees, testing |
| **Embedded** | nerves_firmware.md | Nerves, firmware, deployment |
| **Error Handling** | error_handling.md, exunit_testing.md (error tests) | Exceptions, tuples, propagation |

## Maintenance

- **Last directory review**: 2025-01-06
- **Update frequency**: Quarterly + when adding new patterns
- **See**: `.update_reminder.md` for file-level status

## How This Relates to docs/ and skills/

### docs/
**Purpose**: Real-world case studies and comprehensive guides (read in full for deep dives)

**Files**:
- `docs/genserver_guide.txt` - Full GenServer design guide (Freshcode.it)
- `docs/genserver_testing.txt` - Testing strategies
- `docs/MCP_COMPARISON.md` - MCP tool comparison
- `docs/igniter-how-to.md` - Igniter usage guide

**When to use**: Need to understand context, theory, or read complete guide.

### skills/
**Purpose**: Domain-specific skill sets with comprehensive guides + examples

**Directories** (examples):
- `skills/otp-patterns/` - OTP supervisor, GenServer patterns
- `skills/liveview-patterns/` - Phoenix LiveView patterns
- `skills/ecto-query-analysis/` - Ecto query patterns
- `skills/exunit-patterns/` - Testing patterns

**When to use**: Need comprehensive skill guide with runnable examples.

### patterns/
**Purpose**: Quick reference for copy-paste patterns (this directory)

**When to use**: Need a specific pattern solution right now.

## Example Workflow

**Problem**: GenServer is blocking schedulers

**Fast Lookup** (with PATTERN_INDEX.md):
1. Check `PATTERN_INDEX.md` → Search for "GenServer blocking schedulers"
2. Find match → genserver.md, Pattern 1
3. Load `genserver.md` → Pattern 1: Non-blocking callbacks
4. See code example → Copy paste solution
5. Check References → `otp_supervisor.md` for supervisor context

**Detailed Lookup** (without index):
1. Check `patterns/genserver.md` → Browse patterns
2. Find Pattern 1: Non-blocking callbacks
3. See code example → Copy paste solution
4. Check References → `otp_supervisor.md` for supervisor context
5. If deeper needed → `docs/genserver_guide.txt` for full guide
6. If comprehensive → `skills/otp-patterns/SKILL.md`

**Time saved with index**: 30 seconds (vs 2-3 minutes searching manually)
