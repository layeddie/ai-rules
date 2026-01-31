# Elixir Pattern Lookup Index

## How to Use This Index

1. Search for your problem in the Quick Problem Search table
2. Load the specified pattern file and section
3. Each pattern includes code examples ready to copy

## Quick Problem Search

| Problem Keywords | Pattern File | Section |
|---------------|--------------|---------|
| offloading, long-running, tasks, cpu-intensive, operations, block | liveview.md | Pattern 1 |
| optimistic, updates, users, wait, slow, server | liveview.md | Pattern 2 |
| streaming, large, lists, livecomponents, queries, nested | liveview.md | Pattern 3 |
| livecomponent, reusability, duplicated, component, code, across | liveview.md | Pattern 4 |
| LiveView, Phoenix, web, realtime, file, uploads | liveview.md | Pattern 5 |
| client-side, information, hooks, liveview, supports, separate | liveview.md | Pattern 6 |
| loading, states, skeleton, show, state, during | liveview.md | Pattern 7 |
| real-time, updates, pubsub, updating, data, changes | liveview.md | Pattern 8 |
| LiveView, Phoenix, web, realtime, error, handling | liveview.md | Pattern 9 |
| async, synchronous, tests, can, interfere, shared | exunit_testing.md | Pattern 1 |
| setup, teardown, repeating, code, across, tests | exunit_testing.md | Pattern 2 |
| describe, organization, related, tests, hard, find | exunit_testing.md | Pattern 3 |
| GenServer, state, process, testing, genservers, isolation | exunit_testing.md | Pattern 4 |
| Phoenix, controller, web, API, integration, testing | exunit_testing.md | Pattern 5 |
| using, factories, fixtures, hardcoded, test, data | exunit_testing.md | Pattern 6 |
| testing, ExUnit, test, mocks, external, dependencies | exunit_testing.md | Pattern 7 |
| tag-based, test, execution, run, only, certain | exunit_testing.md | Pattern 8 |
| GenServer, state, process, task, agent, genserver | concurrent_tasks.md | Pattern 1 |
| genstage, back-pressure, producer, overwhelms, consumer | concurrent_tasks.md | Pattern 2 |
| task, supervisor, pooling, multiple, parallel, workers | concurrent_tasks.md | Pattern 3 |
| genstage, consumer, groups, multiple, consumers, different | concurrent_tasks.md | Pattern 4 |
| rate, limiting, genstage, protect, downstream, services | concurrent_tasks.md | Pattern 5 |
| ordered, processing, genstage, messages, must, processed | concurrent_tasks.md | Pattern 6 |
| partitionsupervisor, load, distribution, workers, distributed, across | concurrent_tasks.md | Pattern 7 |
| timeout, handling, concurrent, operations, long-running, tasks | concurrent_tasks.md | Pattern 8 |
| process, registry, dynamic, supervision, discover, manage | concurrent_tasks.md | Pattern 9 |
| basic, firmware, build, building, target, board | nerves_firmware.md | Pattern 1 |
| cross-compilation, targets, building, different, board, architectures | nerves_firmware.md | Pattern 2 |
| firmware, burning, card, flashing, physical, media | nerves_firmware.md | Pattern 3 |
| partition, updates, firmware, can, brick, devices | nerves_firmware.md | Pattern 4 |
| over-the-air, ota, updates, updating, firmware, across | nerves_firmware.md | Pattern 5 |
| device, configuration, runtime, devices, different, configs | nerves_firmware.md | Pattern 6 |
| native, nifs, implemented, functions, hardware-specific, code | nerves_firmware.md | Pattern 7 |
| Nerves, embedded, firmware, custom, nerves, system | nerves_firmware.md | Pattern 8 |
| fleet, management, managing, multiple, devices | nerves_firmware.md | Pattern 9 |
| testing, ExUnit, test, nerves, applications, hardware-specific | nerves_firmware.md | Pattern 10 |
| feature, flags | graceful_degradation.md | Pattern 1 |
| fallback, services | graceful_degradation.md | Pattern 2 |
| caching, cache, ETS, degradation | graceful_degradation.md | Pattern 3 |
| progressive, degradation | graceful_degradation.md | Pattern 4 |
| load, shedding | graceful_degradation.md | Pattern 5 |
| returning, tuple, results, explicit, success, error | error_handling.md | Pattern 1 |
| using, statements, chain, operations, early, exit | error_handling.md | Pattern 2 |
| try, rescue, exception, handling, graceful, error | error_handling.md | Pattern 3 |
| error, handling, exception, raising, custom, errors | error_handling.md | Pattern 4 |
| error, handling, exception, logging, structured, information | error_handling.md | Pattern 5 |
| error, handling, exception, supervisor, let, supervisors | error_handling.md | Pattern 6 |
| error, handling, exception, user-facing, messages, meaningful | error_handling.md | Pattern 7 |
| Ash, resources, domain-driven, ash, error, handling | error_handling.md | Pattern 8 |
| GenServer, state, process, ets, genserver, decision | ets_performance.md | Pattern 1 |

## Pattern File Directory

### Ash Framework

**migration_strategies.md** (10 patterns)
- Ash Automatic Migration Generation → P1
- Ash Data Preservation → P2


**ash_resources.md** (10 patterns)
- Domain-Driven Resource Design → P1
- Ash API for Resource Orchestration → P2



### Embedded Systems

**nerves_firmware.md** (10 patterns)
- Basic Firmware Build → P1
- Cross-Compilation Targets → P2



### Error Handling

**error_handling.md** (8 patterns)
- Returning Tuple Results → P1
- Using `with` Statements → P2



### OTP/Supervision

**otp_supervisor.md** (12 patterns)
- OneForOne Strategy for Independent Servi → P1
- OneForAll Strategy for Dependent Service → P2



### Resilience

**graceful_degradation.md** (5 patterns)
- Feature Flags → P1
- Fallback Services → P2


**retry_strategies.md** (5 patterns)
- Exponential Backoff with Jitter → P1
- Retry with Specific Errors → P2


**bulkhead_patterns.md** (5 patterns)
- Task Pool Limitation → P1
- Database Connection Pool → P2



### State Management

**concurrent_tasks.md** (9 patterns)
- Task vs Agent vs GenServer Decision Matr → P1
- GenStage for Back-Pressure → P2


**ets_performance.md** (8 patterns)
- ETS vs GenServer Decision Matrix → P1
- GenServer with Agent for Read-Write → P2


**genserver.md** (10 patterns)
- Non-blocking GenServer Callbacks → P1
- ETS vs GenServer for Read-Heavy Workload → P2



### Testing

**exunit_testing.md** (8 patterns)
- Async vs Synchronous Tests → P1
- setup and teardown → P2



### Web Patterns

**liveview.md** (9 patterns)
- Offloading Long-Running Tasks → P1
- Optimistic UI Updates → P2


**phoenix_controllers.md** (9 patterns)
- Thin Controllers with Context Delegation → P1
- Error Handling with put_flash → P2



## Cross-Reference Map

| Problem | Primary Pattern | Related Patterns |
|---------|----------------|------------------|
| Concurrent state | genserver.md | ets, concurrent, otp |
| Web UI performance | liveview.md | phoenix, tasks, ets |
| Fault-tolerant | otp_supervisor.md | genserver, errors, degradation |
| Resilience | retry_strategies.md | bulkhead, degradation |
| Database | ash_resources.md | migration, ecto |
| Error handling | error_handling.md | exunit, genserver |
| Testing | exunit_testing.md | errors, liveview |
| Performance | ets_performance.md | genserver, tasks |
| Caching | ets_performance.md | tasks, degradation |

## Validation Checklist

### Pre-Publish Validation

- [ ] All 14 pattern files are listed in Pattern File Directory
- [ ] All ~120 patterns have corresponding table entries
- [ ] No duplicate keywords in same category
- [ ] All pattern numbers match actual pattern sections
- [ ] All cross-references are valid (files exist)
- [ ] High-level keywords are unique across categories
- [ ] Specific keywords include both Problem and Concept terms
- [ ] File names are lowercase with underscores
- [ ] Pattern numbers are correct (sequential starting at 1)
- [ ] Token count is within target (~2K tokens ±10%)

### Post-Publish Validation

- [ ] AI can successfully search for problem keywords
- [ ] AI can navigate to correct pattern file and section
- [ ] No broken links to pattern files
- [ ] Cross-references are bidirectional (if A links to B, B links to A)
- [ ] Category groupings are logical and intuitive
- [ ] Pattern File Directory matches actual pattern count per file

## Maintenance

**Last Updated**: 2026-01-30
**Total Pattern Files**: 14
**Total Patterns**: 118
**Total Keyword Mappings**: 50

### When to Update

- Add new pattern file → Run update script + review
- Modify existing pattern → Update keywords manually or run script
- Remove pattern file → Run script to clean up references
- Change pattern numbers → Run script to update section numbers

### Update Process

1. **Automated Update:**
```bash
cd /Users/elay14/projects/2026/ai-rules/patterns
elixir update_pattern_index.exs
```

2. **Manual Review:**
- Check generated keywords for accuracy
- Verify cross-references are valid
- Ensure pattern numbers match actual sections

3. **Validation:**
- Complete Validation Checklist (above)
- Test AI search with sample queries

4. **Commit:**
```bash
git add PATTERN_INDEX.md update_pattern_index.exs
git commit -m "feat: update pattern index - [description]"
```
