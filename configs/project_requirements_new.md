# Project Requirements

**Project Name**: Test Elixir/Ash/Phoenix/LiveView Project
**Created**: [Date]
**Language**: Elixir 1.17+
**Framework**: Phoenix 1.7.14+, Ash 3.4+, LiveView 1.0.0+
**Database**: PostgreSQL 16
**Testing Framework**: ExUnit, StreamData, PropCheck
**LiveView Version**: Phoenix LiveView 1.0.0+

---

## 1. Project Overview

**Purpose**: Test project for validating `.ai_rules` repository with Elixir, Ash, Phoenix, and LiveView integration.

**Target Users**: Developers testing `.ai_rules` repository for compatibility with OpenCode, mgrep, and Serena MCP.

**Key Features**:
- Domain Resource Action pattern with Ash framework
- LiveView UI for real-time features
- OTP supervision tree architecture
- TDD workflow with comprehensive testing
- mgrep + Serena MCP integration
- Multi-session development workflow (plan, build, review)

---

## 2. Technical Stack

**Elixir Version**: 1.17.3
**Phoenix Version**: 1.7.14
**Ash Version**: 3.4.12
**Ash Dependencies**:
- `ash`: Core Ash framework
- `ash_postgres`: PostgreSQL adapter
- `ash_authentication`: JWT authentication
- `ash_phoenix`: Phoenix LiveView integration
- `ash_json_api`: JSON API layer
- `ash_policy`: Authorization policies
- `ash_graphql`: GraphQL support (optional)

**Database**: PostgreSQL 16 via Ash Postgres

**Testing Framework**: 
- `ex_unit`: Built-in testing framework
- `stream_data`: Property-based testing
- `propcheck`: Alternative property-based testing
- `ex_machina`: ExMachina for concurrent testing (optional)

**LiveView**: Phoenix LiveView 1.0.0+

**Additional Libraries**:
- `jason`: JSON parsing
- `phoenix_live_view`: LiveView framework
- `telemetry`: Observability and metrics
- `gettext`: Internationalization

**Development Tools**:
- `credo`: Code quality and static analysis
- `dialyxir`: Type checking (optional)
- `ex_doc`: Documentation generation

---

## 3. LLM Configuration

### 3.1. Planning Phase (Architecture & Design)

**Strategy**: Configurable (selected in this document)

**Preferred Models**:

**Primary**: Claude 3.5 Sonnet (API) - Strong architectural reasoning
- **Fallback**: Claude 3 Opus
- **Local**: Llama 3.1 70B-instruct (Ollama/MLX)

**Local Provider**:
- **Ollama**: http://localhost:11434
- **MLX**: GPU acceleration (M2 Max, up to 5 GPUs)

**API Provider**:
- **OpenCode Zen**: Enabled for curated models
- **Anthropic**: Claude 3.5 Sonnet / Claude 3 Opus
85- **OpenAI**: GPT-4.1/o-mini (optional)
86- **Groq**: Groq Llama 3.1 70B (fast, cost-effective)
87- **xAI**: Grok-2 / Grok-1 (optional, API key required)

88-
89-**Rationale**:
90-- **Groq**: Fast inference, very cost-effective ($0.59/M tokens), good for quick iterations
91-- **xAI**: High-performance models with good reasoning (optional, API key required)
92-- **OpenAI**: GPT-4.1/o-mini for specialized tasks (optional)

93-
94-**Environment Variables**:
95- `ANTHROPIC_API_KEY`: Required for Anthropic models
96- `OPENAI_API_KEY`: Required for OpenAI models
97- `GROQ_API_KEY`: Required for Groq models
98- `XAI_API_KEY`: Required for xAI models (optional)
99- `OLLAMA_HOST`: http://localhost:11434
100- `MLX_TENSOR_PARALLEL`: 5 (M2 Max optimization)
101- `MLX_MAX_GPUS`: 5
102- `MLX_VRAM_LIMIT`: 45GB
103- `MLX_QUANTIZATION_BITS`: 4
104- `MLX_BATCH_PLAN`: 1
105- `LMSTUDIO_HOST`: http://localhost:1234/v1
106-
107-## Token Efficiency Mode (New)
108-
109-**Mode**: **BALANCED** (default: always load system + minimal project, conditionally load skills)
110-
111-**Strategy**:
112-- **Always Load**: System role prompt + project requirements summary (first 100 lines)
113-- **Conditionally Load**: Skills based on task (e.g., otp-patterns for GenServer)
114-- **Cache Prompts**: Frequently used prompts (roles, guardrails)
115-- **Stream Large Files**: Files >8k tokens use streaming
116-- **On-Demand Tools**: Load skills only when needed
117-
118-**Expected Token Savings**: 20-40% vs loading all context upfront
119-
120-**Configuration Override**:
121-- Set `"token_efficiency": "efficient"` to load minimal (role only)
122-- Set `"token_efficiency": "rich"` to load everything upfront (not recommended)
123-- Set `"token_efficiency": "balanced"` to load system + conditional (recommended default)
124-
125-**Tool Selection Strategy**:
126| Task | Optimal Tool | Token Savings |
127|--------|---------------|----------------|
128| **Semantic code search** | mgrep (embeddings) | 40-60% less code context |
129| **Multi-file refactor** | Serena (AST-aware) | 30-40% less with smart edits |
130| **DB query optimization** | Ecto analysis skill | 50% less, targeted patterns |
131| **Security review** | Security patterns | 70% less, focused rules |
132| **Nerves patterns** | Nerves skill | 60% less, hardware-specific |
133| **Project setup** | Plugin template | 80% less, no generation needed |
134-
135-**Caching Strategy**:
136- Cache frequently used prompts (roles, guardrails, common operations)
137- Cache skill results when loaded once
138- Use environment variables for caching when appropriate
139-
140-**Streaming Strategy**:
141- Stream tool outputs to reduce initial context window
142- Use line-by-line processing for large files
143- Token limit: ~8k tokens per stream buffer
144-
145-**On-Demand Loading**:
146- Skills: Load only when task-relevant
147- Roles: Load secondary roles only when explicitly invoked
148- External docs: Load on-demand (Nerves docs, API docs)
149-
150-**Configuration Override**:
151- Set `"token_efficiency": "balanced"` (default)
152- Set `"cache_prompts": true` (recommended)
153- Set `"stream_large_content": true` (optional, for large files)
154- Set `"on_demand_skills": true` (recommended)
155-
