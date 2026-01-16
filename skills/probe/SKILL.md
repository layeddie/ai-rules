# Probe - AST-Aware Code Search

## Overview
Local, AI-ready code intelligence tool combining ripgrep speed with tree-sitter AST parsing. Provides semantic code search without embeddings generation, working directly on codebase like an elastic search for code.

**Source**: https://probelabs.com/

## When to Use
- Backup semantic search when mgrep is unavailable
- Multi-language projects (polyglot repos)
- AST pattern matching (find code structures, not just text)
- Token-aware search for AI context windows
- Local-first privacy (runs without API calls)

## Key Capabilities
- ✅ Semantic code search (natural language queries)
- ✅ AST-aware pattern matching (code structures, not text)
- ✅ Elastic search syntax (operators, boolean logic)
- ✅ Token-aware results (limits to fit AI context windows)
- ✅ MCP server (via npx)
- ✅ No indexing required (works directly on code)
- ✅ Multi-language support (30+ languages via tree-sitter)

## Quick Start

### Install via NPX
```bash
npx -y @buger/probe-mcp
```

### MCP Configuration
```json
{
  "mcpServers": {
    "probe": {
      "type": "local",
      "command": ["npx", "-y", "@buger/probe-mcp"]
    }
  }
}
```

### Install Globally
```bash
npm install -g @buger/probe-mcp@latest
```

## MCP Tools

### search_code
Search code in a specified directory using Elasticsearch-like query syntax with session-based caching.

```json
{
  "path": "/path/to/your/project",
  "query": "authentication flow",
  "maxTokens": 20000
}
```

### query_code
Find specific code structures (functions, classes, etc.) using tree-sitter patterns.

```json
{
  "path": "/path/to/your/project",
  "pattern": "fn $NAME($$PARAMS) $$$BODY",
  "language": "rust"
}
```

### extract_code
Extract code blocks from files based on file paths and optional line numbers.

```json
{
  "path": "/path/to/your/project",
  "files": ["/path/to/your/project/src/main.rs:42"],
  "prompt": "explainer",
  "instructions": "Explain this function",
  "contextLines": 3
}
```

## Search Examples

### Basic Semantic Search
```bash
probe search "error handling" ./src
```

### Token-Limited Search
```bash
probe search "authentication" --max-tokens 8000 ./src
```

### Elastic Search Syntax
```bash
# Boolean operators
probe search "(login OR auth) AND NOT test" ./src

# Grouping
probe search "(api OR database) AND (cache OR queue)" ./src

# Required terms
probe search "+authentication +authorization" ./src

# Excluded terms
probe search "data -validation" ./src
```

### AST Pattern Matching
```bash
# Find all functions
probe query -p "fn $NAME($$PARAMS) $$$BODY" ./src

# Find React useEffect hooks
probe query -p "useEffect(() => $$$BODY, [$$$DEPS])" ./src
```

### Extract Examples
```bash
# Extract by line number
probe extract src/auth.js:15

# Extract by function name
probe extract "src/main.rs#authenticateUser"

# Extract from test output
go test ./... | probe extract
```

## Integration with ai-rules
- **Plan Mode**: Use Probe for broad code discovery when exploring new codebases
- **Build Mode**: Use Probe for AST pattern verification and code structure analysis
- **Review Mode**: Use Probe for code pattern validation across codebase

### Agent Roles
- **Architect**: Use Probe for AST pattern discovery during architecture planning
- **Orchestrator**: Use Probe for code structure verification during implementation
- **Reviewer**: Use Probe for AST pattern validation across codebase

### Tooling Integration
- Use Probe as backup semantic search (use when mgrep unavailable)
- Use Probe for multi-language projects (non-Elixir code)
- Use Probe for AST pattern matching (complement Codicil's Elixir-native search)

### Comparison to Codicil
| Feature | Codicil | Probe |
|---------|---------|-------|
| **Language** | Elixir-native | Multi-language (30+) |
| **Indexing** | Compiler-level (automatic) | No indexing required |
| **LLM Support** | Multi-provider | None (standalone search) |
| **Primary Use** | Elixir projects | Backup / polyglot |
| **Integration** | jido_ai, anubis_mcp | mgrep |

## Advantages Over mgrep/Serena
✅ **No embeddings generation** (instant search)
✅ **AST-aware** (understands code structure)
✅ **Multi-language** (works with any tree-sitter language)
✅ **Local-only** (no API calls needed)
✅ **Elastic search syntax** (powerful boolean logic)

## Best Practices
- Use Probe for multi-language projects or polyglot repos
- Use Probe's AST pattern matching for specific code structures
- Use token limits to fit AI context windows (prevent overflow)
- Combine with Codicil for Elixir-specific analysis
- Use natural language queries for semantic search
- Leverage Elastic search syntax for complex queries

## Troubleshooting
- Verify npx is available (for MCP server mode)
- Check Node.js version is 18+ (required)
- Verify project path is correct
- Test Probe with simple search queries first
- Increase timeout for large codebases (default 30s, can increase)
- Check MCP client configuration (Claude Desktop, etc.)

## Resources
- Website: https://probelabs.com/
- GitHub: https://github.com/buger/probe
- Documentation: https://probelabs.com/mcp-server/
- License: Apache 2.0 (permissive)

## Configuration Options

### Timeout
```json
{
  "mcpServers": {
    "probe": {
      "command": ["npx", "-y", "@buger/probe-mcp"],
      "args": ["--timeout", "60"]
    }
  }
}
```

### Custom Search Paths
```json
{
  "mcpServers": {
    "probe": {
      "command": ["npx", "-y", "@buger/probe-mcp"],
      "env": {
        "PROBE_DEFAULT_PATHS": "/path/to/project1,/path/to/project2"
      }
    }
  }
}
```

### Token Limits
```json
{
  "mcpServers": {
    "probe": {
      "command": ["npx", "-y", "@buger/probe-mcp"],
      "env": {
        "PROBE_MAX_TOKENS": "20000"
      }
    }
  }
}
```
