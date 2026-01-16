# Jido AI Framework

## Overview
Comprehensive Elixir framework for building sophisticated AI agents and workflows. Extends Jido framework with LLM capabilities, advanced reasoning techniques, and stateful conversation management.

**Source**: https://github.com/agentjido/jido_ai (upstream)  
**Fork**: https://github.com/layeddie/jido_ai (your fork)

## When to Use
- Multi-agent orchestration (coordinate multiple specialized agents)
- Advanced reasoning workflows (Chain-of-Thought, ReAct, Tree-of-Thoughts, GEPA)
- Multi-provider LLM access (57+ providers)
- Complex problem-solving with stateful conversations
- Local LLM support (Ollama, LM Studio)

## Key Capabilities
- ✅ 57+ LLM providers (OpenAI, Anthropic, Google, Mistral, local)
- ✅ Advanced reasoning strategies:
  - Chain of Thought (+8-15% accuracy)
  - ReAct (+27% accuracy)
  - Self-Consistency (+17.9% accuracy)
  - Tree of Thoughts (+74% accuracy)
  - GEPA (+10.19% accuracy)
- ✅ Structured prompts (EEx + Liquid templates)
- ✅ Tool integration (function calling with schema conversion)
- ✅ Conversation management (stateful, ETS storage)
- ✅ Context window management (token counting, truncation)

## Quick Start
```elixir
# mix.exs
{:jido_ai, "~> 0.5.3"}
```

```elixir
alias Jido.AI.{Model, Prompt}
alias Jido.AI.Actions.ReqLlm.ChatCompletion

# Create model
{:ok, model} = Model.from({:anthropic, [model: "claude-3-5-sonnet"]})

# Create prompt
prompt = Prompt.new(:user, "What is the capital of France?")

# Get response
{:ok, result} = ChatCompletion.run(%{model: model, prompt: prompt}, %{})
IO.puts(result.content)
```

## Integration with ai-rules
- **Plan Mode**: Use jido_ai for multi-agent exploration of codebase architecture
- **Build Mode**: Use jido_ai reasoning strategies for complex implementation problems
- **Review Mode**: Validate reasoning quality and consistency across agent workflows

### Agent Roles
- **Architect**: Design multi-agent architectures using jido_ai
- **Orchestrator**: Coordinate multiple specialized agents with jido_ai
- **Reviewer**: Validate reasoning quality and agent behavior patterns

### Tooling Integration
- Use jido_ai with anubis_mcp for agent + MCP server workflows
- Use jido_ai with swarm_ex for lightweight agent coordination
- Use jido_ai with codicil for reasoning + code understanding

## Reasoning Strategies

### Chain of Thought
**Purpose**: Step-by-step reasoning

**Accuracy Gain**: +8-15%

**Use Case**: Complex multi-step problems requiring systematic breakdown

**Pattern**:
```elixir
defmodule MyApp.ChainOfThought do
  alias Jido.AI.Runners.ChainOfThought

  def solve(problem, config \\ %{}) do
    ChainOfThought.run(%{
      problem: problem,
      llm: config.llm,
      max_iterations: 5
    })
  end
end
```

### ReAct
**Purpose**: Reasoning with tool use

**Accuracy Gain**: +27%

**Use Case**: Problems requiring external tools or APIs

**Pattern**:
```elixir
defmodule MyApp.ReAct do
  alias Jido.AI.Runners.ReAct

  def solve(problem, config \\ %{}) do
    ReAct.run(%{
      problem: problem,
      llm: config.llm,
      tools: config.tools
    })
  end
end
```

### Self-Consistency
**Purpose**: Multiple reasoning paths with voting

**Accuracy Gain**: +17.9%

**Use Case**: Uncertain problems requiring diverse perspectives

**Pattern**:
```elixir
defmodule MyApp.SelfConsistency do
  alias Jido.AI.Runners.SelfConsistency

  def solve(problem, config \\ %{}) do
    SelfConsistency.run(%{
      problem: problem,
      llm: config.llm,
      paths: 3
    })
  end
end
```

### Tree of Thoughts
**Purpose**: Tree search exploration

**Accuracy Gain**: +74%

**Use Case**: Problems requiring exploration of solution space

**Pattern**:
```elixir
defmodule MyApp.TreeOfThoughts do
  alias Jido.AI.Runners.TreeOfThoughts

  def solve(problem, config \\ %{}) do
    TreeOfThoughts.run(%{
      problem: problem,
      llm: config.llm,
      max_depth: 3
    })
  end
end
```

### GEPA
**Purpose**: Evolutionary prompt optimization

**Accuracy Gain**: +10.19%

**Use Case**: Problems requiring iterative refinement

## Resources
- HexDocs: https://hexdocs.pm/jido_ai
- Upstream: https://github.com/agentjido/jido_ai
- User Guides: https://github.com/layeddie/jido_ai/tree/main/guides/user
- Developer Guides: https://github.com/layeddie/jido_ai/tree/main/guides/developer

## Provider Configuration

### Supported Providers (57+)
```elixir
# OpenAI
config :jido_ai, Jido.AI.Providers.Anthropic,
  api_key: System.get_env("OPENAI_API_KEY"),
  models: [
    gpt_4o: "gpt-4o",
    gpt_4_turbo: "gpt-4-turbo"
  ]

# Anthropic
config :jido_ai, Jido.AI.Providers.Anthropic,
  api_key: System.get_env("ANTHROPIC_API_KEY"),
  models: [
    claude_3_5_sonnet: "claude-3-5-sonnet-20241022",
    claude_3_opus: "claude-3-opus-20240219"
  ]

# Google
config :jido_ai, Jido.AI.Providers.Google,
  api_key: System.get_env("GOOGLE_API_KEY"),
  models: [
    gemini_1_5_pro: "gemini-1.5-pro",
    gemini_1_5_flash: "gemini-1.5-flash"
  ]

# Local (Ollama)
config :jido_ai, Jido.AI.Providers.Ollama,
  base_url: "http://localhost:11434",
  models: [
    llama3: "llama3"
  ]
```

## Prompt Templates

### EEx Templates
```elixir
defmodule MyApp.Prompts do
  alias Jido.AI.Prompt

  def system_prompt do
    Prompt.new(:system, """
    You are an expert Elixir/BEAM developer.
    Follow OTP best practices and TDD workflow.
    Use Domain Resource Action pattern.
    Prioritize code quality and test coverage.
    """)
  end

  def user_prompt(template \\ "") do
    Prompt.new(:user, """
    Question: {{question}}
    Context: {{context}}
    Instructions: {{instructions}}
    """)
  end
end
```

### Liquid Templates
```elixir
defmodule MyApp.LiquidPrompts do
  use Jido.AI.Prompt.Templates.Liquid

  def system_prompt do
    """
    {% if is_authenticated %}
      You are authenticated as {{user_name}}.
    {% endif %}
    
    {{content}}
    """
  end
end
```

## Conversation Management

### Stateful Conversations
```elixir
defmodule MyApp.Conversation do
  use Jido.AI.Conversation

  def start(user_id) do
    Conversation.start(user_id)
  end

  def add_message(conversation_id, role, content) do
    Conversation.add_message(conversation_id, role, content)
  end

  def get_history(conversation_id) do
    Conversation.get_history(conversation_id)
  end

  def get_context(conversation_id, max_tokens \\ 8000) do
    Conversation.get_context(conversation_id, max_tokens: max_tokens)
  end
end
```

## Best Practices
- Start with Chain of Thought for simple problems
- Use ReAct when tools are available
- Try Tree of Thoughts for exploration tasks
- Use Self-Consistency for uncertain problems
- Use GEPA for iterative refinement
- Monitor token usage and context window
- Choose appropriate LLM provider for task complexity
- Leverage conversation management for multi-turn interactions

## Troubleshooting
- Verify API keys are set correctly
- Check provider configuration for correct models
- Monitor reasoning performance (accuracy, token usage)
- Test reasoning strategies on sample problems
- Verify ETS storage is available for conversations
- Review prompt templates for effectiveness
