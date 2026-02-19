# Pattern Decision Trees

**Purpose**: Quick decision trees for selecting the right pattern

**Last Updated**: 2026-02-19

---

## How to Use These Decision Trees

1. Start at the top of the relevant tree
2. Answer each question based on your situation
3. Follow the path to find the recommended pattern file
4. Load that file and look for the specific pattern number

---

## 1. State Management Decision Tree

```
START: Need to manage state?
│
├─ YES: What kind of state?
│   │
│   ├─ Read-heavy, immutable data
│   │   └─ Use ETS → ets_performance.md (P1, P2, P3)
│   │
│   ├─ Read-write, mutable state
│   │   └─ Is state complex?
│   │       ├─ YES: Use GenServer → genserver.md (P1, P2, P3)
│   │       └─ NO: Use Agent → concurrent_tasks.md (P1)
│   │
│   ├─ Need process isolation
│   │   └─ Use GenServer → genserver.md (P4, P5)
│   │
│   └─ Temporary, async result
│       └─ Use Task → concurrent_tasks.md (P1)
│
└─ NO: Stateless operation
    └─ Use plain functions
```

**Quick Lookup Table**:

| State Type | Access Pattern | Recommended Pattern |
|------------|----------------|---------------------|
| Read-heavy | Mostly reads | ETS (ets_performance.md P1-P3) |
| Read-write | Equal reads/writes | GenServer (genserver.md P1-P3) |
| Simple | Low complexity | Agent (concurrent_tasks.md P1) |
| Isolated | Process-per-entity | GenServer + Registry (genserver.md P4-P5) |
| Temporary | Async computation | Task (concurrent_tasks.md P1) |

---

## 2. Concurrency Decision Tree

```
START: Need concurrent operations?
│
├─ YES: How many operations?
│   │
│   ├─ One long-running task
│   │   └─ Use Task.async → concurrent_tasks.md (P1)
│   │
│   ├─ Multiple parallel tasks
│   │   └─ Need back-pressure?
│   │       ├─ YES: Use GenStage → concurrent_tasks.md (P2, P3)
│   │       └─ NO: Use Task.async_stream → concurrent_tasks.md (P1)
│   │
│   ├─ Producer-consumer pattern
│   │   └─ Use GenStage → concurrent_tasks.md (P2, P4, P5)
│   │
│   └─ Rate limiting needed
│       └─ Use GenStage + RateLimiter → concurrent_tasks.md (P5)
│
└─ NO: Sequential execution
    └─ Use regular function calls
```

**Quick Lookup Table**:

| Concurrency Type | Scale | Recommended Pattern |
|------------------|-------|---------------------|
| One task | Single | Task.async (concurrent_tasks.md P1) |
| Many tasks | Multiple | Task.async_stream (concurrent_tasks.md P1) |
| Producer-consumer | Streaming | GenStage (concurrent_tasks.md P2, P4) |
| Back-pressure | Large scale | GenStage + Buffer (concurrent_tasks.md P2) |
| Rate limiting | External services | GenStage + Rate Limiter (concurrent_tasks.md P5) |
| Load distribution | High traffic | PartitionSupervisor (concurrent_tasks.md P7) |

---

## 3. Error Handling Decision Tree

```
START: How to handle errors?
│
├─ Expected failures (normal flow)
│   └─ Use {:ok, result} | {:error, reason} → error_handling.md (P1)
│
├─ Chain multiple operations
│   └─ Use with statement → error_handling.md (P2)
│
├─ Unexpected failures (exceptional)
│   └─ Use try/rescue → error_handling.md (P3, P4)
│
├─ Need to log/recover
│   └─ Use custom errors + logging → error_handling.md (P4, P5)
│
├─ Let supervisor handle
│   └─ Use let it crash → error_handling.md (P6)
│
└─ User-facing errors
    └─ Use meaningful messages → error_handling.md (P7)
```

**Quick Lookup Table**:

| Error Scenario | Expected? | Recommended Pattern |
|----------------|-----------|---------------------|
| Normal operation | Yes | Tuple results (error_handling.md P1) |
| Chained operations | Yes | with statement (error_handling.md P2) |
| Unexpected crash | No | try/rescue (error_handling.md P3) |
| Need recovery | No | Custom errors (error_handling.md P4) |
| Need logging | No | Structured logging (error_handling.md P5) |
| Supervisor handling | No | Let it crash (error_handling.md P6) |
| User message | Yes | Meaningful errors (error_handling.md P7) |
| Ash resources | Yes | Ash error handling (error_handling.md P8) |

---

## 4. Testing Decision Tree

```
START: What are you testing?
│
├─ GenServer process
│   └─ Use start_supervised! → exunit_testing.md (P4)
│       └─ Set async: false
│
├─ Phoenix controller
│   └─ Use ConnCase → exunit_testing.md (P5)
│
├─ LiveView component
│   └─ Use LiveViewTest → liveview.md (testing patterns)
│
├─ External dependencies
│   └─ Use mocks/stubs → exunit_testing.md (P7)
│
├─ Need test data
│   └─ Use factories → exunit_testing.md (P6)
│
├─ Run specific tests
│   └─ Use tags → exunit_testing.md (P8)
│
└─ Integration testing
    └─ Use DataCase/ConnCase → exunit_testing.md (P5)
```

**Quick Lookup Table**:

| Test Type | Isolation Needed? | Recommended Pattern |
|-----------|-------------------|---------------------|
| GenServer | Yes | start_supervised! (exunit_testing.md P4) |
| Controller | No | ConnCase (exunit_testing.md P5) |
| LiveView | No | LiveViewTest (liveview.md) |
| External API | Yes | Mocks (exunit_testing.md P7) |
| Test data | No | Factories (exunit_testing.md P6) |
| Tagged tests | No | Tags (exunit_testing.md P8) |
| Setup/teardown | Yes | setup macro (exunit_testing.md P2) |

---

## 5. Phoenix/Web Decision Tree

```
START: Building Phoenix feature?
│
├─ Real-time UI updates
│   └─ Use LiveView → liveview.md (P1-P9)
│       ├─ Long task: P1
│       ├─ Optimistic UI: P2
│       └─ Streaming: P3
│
├─ REST API endpoint
│   └─ Use Controller → phoenix_controllers.md (P1-P9)
│       ├─ Thin controllers: P1
│       ├─ Error handling: P2
│       └─ JSON responses: P3-P5
│
├─ File uploads
│   └─ Use LiveView uploads → liveview.md (P5)
│
├─ Client-side interaction
│   └─ Use LiveView hooks → liveview.md (P6)
│
├─ Loading states
│   └─ Use skeletons → liveview.md (P7)
│
└─ Real-time updates
    └─ Use PubSub → liveview.md (P8)
```

**Quick Lookup Table**:

| Feature Type | Real-time? | Recommended Pattern |
|--------------|------------|---------------------|
| Dynamic UI | Yes | LiveView (liveview.md P1-P9) |
| Static API | No | Controller (phoenix_controllers.md P1-P9) |
| File upload | Yes | LiveView uploads (liveview.md P5) |
| Client interaction | Yes | LiveView hooks (liveview.md P6) |
| Loading state | Yes | Skeleton loading (liveview.md P7) |
| Real-time updates | Yes | PubSub (liveview.md P8) |

---

## 6. Database/Ecto Decision Tree

```
START: Working with database?
│
├─ Schema design
│   └─ Use Ash resources → ash_resources.md (P1-P10)
│
├─ Migrations
│   └─ Use Ash migrations → migration_strategies.md (P1-P10)
│
├─ Query optimization
│   └─ Check N+1 patterns → ecto-query-analysis (skill)
│
├─ Multi-tenancy
│   └─ Check advanced-database (skill)
│
└─ Performance
    └─ Check ets_performance.md for caching
```

**Quick Lookup Table**:

| Database Task | Complexity | Recommended Pattern |
|---------------|------------|---------------------|
| Schema design | High | Ash resources (ash_resources.md) |
| Migrations | Medium | Ash migrations (migration_strategies.md) |
| N+1 queries | Medium | Ecto preloading (ecto-query-analysis skill) |
| Caching | High | ETS caching (ets_performance.md) |
| Multi-tenant | High | Schema/row isolation (advanced-database skill) |

---

## 7. OTP/Supervision Decision Tree

```
START: Building supervision tree?
│
├─ Independent services
│   └─ Use one_for_one → otp_supervisor.md (P1)
│
├─ Dependent services
│   └─ Use one_for_all → otp_supervisor.md (P2)
│
├─ Service pools
│   └─ Use rest_for_one → otp_supervisor.md (P3)
│
├─ Runtime children
│   └─ Use DynamicSupervisor → otp_supervisor.md (P4)
│
├─ Prevent restart loops
│   └─ Use max_restarts → otp_supervisor.md (P5)
│
├─ Load distribution
│   └─ Use PartitionSupervisor → otp_supervisor.md (P6)
│
├─ Complex hierarchy
│   └─ Use nested supervisors → otp_supervisor.md (P7)
│
└─ One-time setup
    └─ Use :temporary → otp_supervisor.md (P8)
```

**Quick Lookup Table**:

| Supervision Need | Strategy | Recommended Pattern |
|------------------|----------|---------------------|
| Independent | one_for_one | otp_supervisor.md (P1) |
| Dependent | one_for_all | otp_supervisor.md (P2) |
| Pools | rest_for_one | otp_supervisor.md (P3) |
| Dynamic | DynamicSupervisor | otp_supervisor.md (P4) |
| Anti-thrashing | max_restarts | otp_supervisor.md (P5) |
| Load balancing | PartitionSupervisor | otp_supervisor.md (P6) |
| Hierarchical | Nested supervisors | otp_supervisor.md (P7) |
| One-time | :temporary | otp_supervisor.md (P8) |

---

## 8. Resilience Decision Tree

```
START: Need fault tolerance?
│
├─ Feature availability
│   └─ Use feature flags → graceful_degradation.md (P1)
│
├─ Service fallback
│   └─ Use fallback services → graceful_degradation.md (P2)
│
├─ Data availability
│   └─ Use caching → graceful_degradation.md (P3)
│
├─ System overload
│   └─ Use load shedding → graceful_degradation.md (P5)
│
├─ Retry failed operations
│   └─ Use exponential backoff → retry_strategies.md (P1, P2)
│
└─ Isolate failures
    └─ Use bulkheads → bulkhead_patterns.md (P1, P2)
```

**Quick Lookup Table**:

| Resilience Need | Pattern Type | Recommended Pattern |
|-----------------|--------------|---------------------|
| Feature toggle | Feature flag | graceful_degradation.md (P1) |
| Service backup | Fallback | graceful_degradation.md (P2) |
| Data backup | Cache | graceful_degradation.md (P3) |
| Overload protection | Load shed | graceful_degradation.md (P5) |
| Retry logic | Backoff | retry_strategies.md (P1-P2) |
| Failure isolation | Bulkhead | bulkhead_patterns.md (P1-P2) |

---

## Usage Example

**Problem**: "I need to cache user sessions"

**Steps**:
1. Look at **State Management Decision Tree**
2. Identify: Read-heavy, immutable data
3. Decision: Use ETS
4. Load: `ets_performance.md`
5. Find: Patterns P1, P2, P3

**Result**: Found caching patterns in 30 seconds vs 2-3 minutes searching manually

---

## Integration with PATTERN_INDEX.md

These decision trees complement the main `PATTERN_INDEX.md`:

- **PATTERN_INDEX.md**: Keyword-based search (exact matches)
- **DECISION_TREES.md**: Scenario-based navigation (conceptual understanding)

**Recommended workflow**:
1. Start with decision tree to narrow down category
2. Use PATTERN_INDEX.md keyword search for specifics
3. Load the pattern file for detailed examples

---

## Maintenance

**Update when**:
- Adding new pattern files
- Changing pattern categorization
- User feedback on decision paths
- New common scenarios emerge

**Update process**:
1. Identify new decision point
2. Add to relevant decision tree
3. Update quick lookup tables
4. Test with real queries
5. Commit with descriptive message

---

**Last Updated**: 2026-02-19
