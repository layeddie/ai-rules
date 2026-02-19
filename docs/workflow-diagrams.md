# ai-rules Workflow Diagrams

**Purpose**: Visual diagrams for better onboarding and understanding of ai-rules workflows

**Last Updated**: 2026-02-19

---

## 1. Multi-Session Workflow

```mermaid
graph TB
    Start[Start Project] --> Plan[Plan Session]
    
    Plan --> |Read-only| PlanTasks[Architecture Design]
    PlanTasks --> P1[mgrep Discovery]
    PlanTasks --> P2[Read Requirements]
    PlanTasks --> P3[Design Supervision Tree]
    PlanTasks --> P4[Document Architecture]
    
    P4 --> PlanOutput[Output: project_requirements.md]
    PlanOutput --> Build[Build Session]
    
    Build --> |Read-Write| BuildTasks[TDD Implementation]
    BuildTasks --> B1[Write Failing Tests]
    BuildTasks --> B2[Implement Code]
    BuildTasks --> B3[Run Tests]
    BuildTasks --> B4[Fix & Refactor]
    
    B4 --> BuildOutput[Output: Tested Code]
    BuildOutput --> |Tests Pass?| Review{Tests Pass?}
    
    Review --> |No| B4
    Review --> |Yes| ReviewSession[Review Session]
    
    ReviewSession --> |Read-only| ReviewTasks[Quality Assurance]
    ReviewTasks --> R1[Cross-Reference Patterns]
    ReviewTasks --> R2[Check OTP Best Practices]
    ReviewTasks --> R3[Analyze Test Coverage]
    ReviewTasks --> R4[Document Findings]
    
    R4 --> ReviewOutput[Output: Review Report]
    ReviewOutput --> |Quality OK?| Quality{Quality OK?}
    
    Quality --> |No| Build
    Quality --> |Yes| Complete[Ready for Commit]
    
    style Plan fill:#e1f5ff
    style Build fill:#fff4e1
    style ReviewSession fill:#f0f0f0
    style Complete fill:#d4edda
```

---

## 2. Tool Selection Decision Tree

```mermaid
graph TD
    Query[User Query] --> Type{Query Type?}
    
    Type --> |Exact Symbol| Exact[Know exact function/module name?]
    Type --> |Regex| Regex[Using regex pattern?]
    Type --> |Conceptual| Concept[Don't know exact terms?]
    Type --> |Broad| Discovery[Broad exploration task?]
    
    Exact --> |Yes| RipgrepExact[Use ripgrep<br/>100% local, instant]
    Exact --> |No| Concept
    
    Regex --> |Yes| RipgrepRegex[Use ripgrep<br/>Full regex power]
    Regex --> |No| Concept
    
    Concept --> |Yes| Mgrep[Use mgrep<br/>Semantic understanding]
    Concept --> |No| Discovery
    
    Discovery --> |Yes| MgrepDiscovery[Use mgrep<br/>Pattern discovery]
    Discovery --> |No| RipgrepExact
    
    RipgrepExact --> Result1[Exact matches<br/>2K tokens avg]
    RipgrepRegex --> Result2[Pattern matches<br/>1-2K tokens]
    Mgrep --> Result3[Semantic results<br/>5-8K tokens]
    MgrepDiscovery --> Result4[Discovery results<br/>6-8K tokens]
    
    style RipgrepExact fill:#d4edda
    style RipgrepRegex fill:#d4edda
    style Mgrep fill:#fff3cd
    style MgrepDiscovery fill:#fff3cd
```

---

## 3. Role Interaction Diagram

```mermaid
graph TB
    subgraph Plan[Plan Session - Architect]
        Arch[Architect Role]
        Arch --> |Design| ArchTasks[System Design<br/>OTP Patterns<br/>Domain Boundaries]
        ArchTasks --> ArchOut[Architecture Plan]
    end
    
    subgraph Build[Build Session - Orchestrator]
        Orch[Orchestrator Role]
        Orch --> |Coordinate| BuildTasks[TDD Workflow<br/>Implementation<br/>Testing]
        
        Orch --> Backend[Backend Specialist]
        Orch --> Frontend[Frontend Specialist]
        Orch --> Database[Database Architect]
        
        Backend --> |API Design| BuildTasks
        Frontend --> |LiveView UI| BuildTasks
        Database --> |Schema Design| BuildTasks
        
        BuildTasks --> BuildOut[Tested Code]
    end
    
    subgraph Review[Review Session - Reviewer + QA]
        Rev[Reviewer Role]
        QA[QA Role]
        
        Rev --> |Verify| RevTasks[OTP Best Practices<br/>Code Quality<br/>Anti-Patterns]
        QA --> |Analyze| QATasks[Test Coverage<br/>Property Testing<br/>Integration Tests]
        
        RevTasks --> RevOut[Review Report]
        QATasks --> QAOut[Coverage Report]
    end
    
    ArchOut --> |Read| Orch
    BuildOut --> |Analyze| Rev
    BuildOut --> |Test| QA
    
    RevOut --> |Feedback| Orch
    QAOut --> |Feedback| Orch
    
    style Arch fill:#e1f5ff
    style Orch fill:#fff4e1
    style Rev fill:#f0f0f0
    style QA fill:#f0f0f0
```

---

## 4. TDD Workflow Diagram

```mermaid
graph LR
    Start[Feature Request] --> Red[Red Phase]
    
    Red --> |Write| WriteTest[Write Failing Test]
    WriteTest --> |Run| TestFails[Test Fails ✓]
    
    TestFails --> Green[Green Phase]
    Green --> |Implement| WriteCode[Write Minimal Code]
    WriteCode --> |Run| TestPasses[Test Passes ✓]
    
    TestPasses --> Refactor[Refactor Phase]
    Refactor --> |Improve| RefactorCode[Refactor Code]
    RefactorCode --> |Run| TestsStillPass[Tests Still Pass ✓]
    
    TestsStillPass --> |More Tests?| MoreTests{More Tests Needed?}
    MoreTests --> |Yes| Red
    MoreTests --> |No| Complete[Feature Complete]
    
    style Red fill:#f8d7da
    style Green fill:#d4edda
    style Refactor fill:#fff3cd
    style Complete fill:#d4edda
```

---

## 5. Git Workflow Diagram

```mermaid
gitGraph
    commit id: "Initial"
    branch feature/add-feature
    checkout feature/add-feature
    commit id: "feat: add feature"
    commit id: "test: add tests"
    commit id: "docs: update docs"
    checkout main
    merge feature/add-feature id: "Squash merge" type: SQUASH
    commit id: "Post-merge cleanup"
    branch fix/bug-fix
    checkout fix/bug-fix
    commit id: "fix: resolve bug"
    checkout main
    merge fix/bug-fix id: "Squash merge" type: SQUASH
```

---

## 6. Skill Dependency Map

```mermaid
graph TB
    subgraph Core[Core Skills]
        OTP[otp-patterns]
        Elixir[elixir-guidelines]
        Testing[test-generation]
    end
    
    subgraph Database[Database Skills]
        Ecto[ecto-query-analysis]
        AdvancedDB[advanced-database]
        Migration[migration-patterns]
    end
    
    subgraph Web[Web Skills]
        LiveView[liveview-patterns]
        Realtime[realtime-patterns]
        API[api-design]
    end
    
    subgraph Infra[Infrastructure Skills]
        Nix[nix]
        Observability[observability]
        Performance[performance-profiling]
    end
    
    OTP --> Testing
    Elixir --> OTP
    Elixir --> Testing
    
    Ecto --> AdvancedDB
    AdvancedDB --> Migration
    
    LiveView --> Realtime
    API --> LiveView
    
    OTP --> Observability
    Testing --> Observability
    AdvancedDB --> Performance
    
    style Core fill:#e1f5ff
    style Database fill:#fff4e1
    style Web fill:#d4edda
    style Infra fill:#f0f0f0
```

---

## 7. Troubleshooting Flowchart

```mermaid
graph TD
    Problem[Problem Occurs] --> Category{Problem Category?}
    
    Category --> |Tool Issue| Tool{Which Tool?}
    Category --> |Test Failure| Test{Test Type?}
    Category --> |Code Quality| Quality{Quality Tool?}
    Category --> |Setup Issue| Setup{Setup Phase?}
    
    Tool --> |mgrep| MgrepIssue[No results from mgrep]
    Tool --> |Serena| SerenaIssue[MCP server not found]
    Tool --> |OpenCode| OpenCodeIssue[Session won't start]
    
    Test --> |Unit| UnitFail[Unit test failing]
    Test --> |Integration| IntegrationFail[Integration test failing]
    Test --> |GenServer| GenServerFail[GenServer test failing]
    
    Quality --> |Format| FormatIssue[Format check fails]
    Quality --> |Credo| CredoIssue[Credo warnings]
    Quality --> |Dialyzer| DialyzerIssue[Type errors]
    
    Setup --> |Dependencies| DepsIssue[Dependencies not installing]
    Setup --> |Nix| NixIssue[Nix shell won't start]
    Setup --> |LLM| LLMIssue[Local LLM not responding]
    
    MgrepIssue --> MgrepSolution[Run: mgrep watch<br/>Use broader queries<br/>Check .mgreprc.yaml]
    SerenaIssue --> SerenaSolution[Install: uv<br/>Test: uvx serena<br/>Check mcp.json]
    OpenCodeIssue --> OpenCodeSolution[Check config path<br/>Verify JSON syntax<br/>Check tool availability]
    
    UnitFail --> UnitSolution[Run: mix test --trace<br/>Check test setup<br/>Review implementation]
    IntegrationFail --> IntegrationSolution[Check database state<br/>Verify fixtures<br/>Test dependencies]
    GenServerFail --> GenServerSolution[Use start_supervised!/1<br/>Set async: false<br/>Avoid sleeps]
    
    FormatIssue --> FormatSolution[Run: mix format<br/>Check .formatter.exs]
    CredoIssue --> CredoSolution[Run: mix credo --explain<br/>Fix warnings one by one]
    DialyzerIssue --> DialyzerSolution[Rebuild PLTs<br/>Fix type specs<br/>Check dependencies]
    
    DepsIssue --> DepsSolution[Run: mix deps.get<br/>Check mix.exs<br/>Update lockfile]
    NixIssue --> NixSolution[Run: nix flake update<br/>Check flake.nix<br/>Verify cachix]
    LLMIssue --> LLMSolution[Check Ollama running<br/>Try smaller model<br/>Check GPU usage]
    
    style Problem fill:#f8d7da
    style MgrepSolution fill:#d4edda
    style SerenaSolution fill:#d4edda
    style UnitSolution fill:#d4edda
```

---

## 8. Directory Structure Map

```mermaid
graph TB
    Root[ai-rules/] --> Roles[roles/]
    Root --> Skills[skills/]
    Root --> Patterns[patterns/]
    Root --> Tools[tools/]
    Root --> Templates[templates/]
    Root --> Docs[docs/]
    Root --> Configs[configs/]
    Root --> Scripts[scripts/]
    
    Roles --> R1[architect.md]
    Roles --> R2[orchestrator.md]
    Roles --> R3[reviewer.md]
    Roles --> R4[qa.md]
    
    Skills --> S1[otp-patterns/]
    Skills --> S2[ecto-query-analysis/]
    Skills --> S3[test-generation/]
    Skills --> S4[observability/]
    
    Patterns --> P1[otp_supervisor.md]
    Patterns --> P2[genserver.md]
    Patterns --> P3[liveview.md]
    Patterns --> P4[exunit_testing.md]
    
    Tools --> T1[opencode/]
    Tools --> T2[claude/]
    Tools --> T3[cursor/]
    
    Templates --> TM1[phoenix-ash-liveview/]
    Templates --> TM2[elixir-library/]
    Templates --> TM3[nerves/]
    
    Docs --> D1[quickstart-agents.md]
    Docs --> D2[mixed-search-strategy.md]
    Docs --> D3[PROJECT_INIT.md]
    
    Configs --> C1[project_requirements.md]
    Configs --> C2[opencode_mcp.json]
    Configs --> C3[nix_flake_template.nix]
    
    Scripts --> SC1[init_project.sh]
    Scripts --> SC2[setup_opencode.sh]
    Scripts --> SC3[validate_requirements.sh]
    
    style Root fill:#e1f5ff
    style Roles fill:#fff4e1
    style Skills fill:#d4edda
    style Patterns fill:#f0f0f0
```

---

## Usage

These diagrams are referenced in:
- `docs/quickstart-agents.md` - Quick reference for agents
- `PROJECT_INIT.md` - Onboarding guide
- `README.md` - Project overview

To view these diagrams:
1. **GitHub**: Automatically renders Mermaid diagrams
2. **VS Code**: Install "Markdown Preview Mermaid Support" extension
3. **Online**: Use [Mermaid Live Editor](https://mermaid.live/)
4. **Docs**: Convert to images with `mmdc` CLI tool

---

## Diagram Maintenance

When adding new diagrams:
1. Follow Mermaid syntax: https://mermaid.js.org/
2. Keep diagrams under 50 nodes for readability
3. Use consistent color scheme
4. Add to this file and reference from relevant docs
5. Test rendering in GitHub before committing

---

**Last Updated**: 2026-02-19
