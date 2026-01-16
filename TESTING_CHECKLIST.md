# New Tools Integration - Testing Checklist

**Purpose**: Comprehensive checklist for testing 5 new Elixir-native tools integration into ai-rules

---

## Overview

**Tools Integrated:**
1. **anubis_mcp** - Elixir MCP SDK (LGPL v3)
2. **jido_ai** - Agent framework + LLM integration (Apache 2.0)
3. **swarm_ex** - Agent orchestration (Apache 2.0)
4. **codicil** - Elixir-native semantic search (MIT)
5. **probe** - AST-aware code search backup (Apache 2.0)

**Total Commits**: 9 commits
**Git Traceability**: Full commit history with descriptive messages

---

## Phase 1: Documentation Testing

### 1.1 Review Tool-Specific SKILL.md Files

**Test**: Verify each SKILL.md file has complete documentation

**Checklist**:
- [ ] `skills/anubis-mcp/SKILL.md` - Comprehensive with LGPL v3 note
- [ ] `skills/jido_ai/SKILL.md` - All reasoning strategies documented
- [ ] `skills/swarm-ex/SKILL.md` - Orchestration patterns included
- [ ] `skills/codicil/SKILL.md` - 5 MCP tools documented
- [ ] `skills/probe/SKILL.md` - AST patterns documented

**Validation Commands**:
```bash
# Count SKILL.md lines
wc -l skills/*/SKILL.md

# Check for placeholders
grep -r "TODO\|FIXME\|XXX" skills/*/SKILL.md
```

### 1.2 Review Tool Comparison Guide

**Test**: Verify `tools/NEW_TOOLS_GUIDE.md` completeness

**Checklist**:
- [ ] All 5 tools included in comparison matrix
- [ ] License notes documented (especially LGPL v3 for anubis_mcp)
- [ ] Integration patterns for each phase (Plan/Build/Review)
- [ ] Tool stack decision guide included
- [ ] Migration notes included

**Validation Commands**:
```bash
# Check tool count in comparison matrix
grep "^\|\s*\*\*" tools/NEW_TOOLS_GUIDE.md | wc -l

# Verify license notes
grep -i "license\|copyleft" tools/NEW_TOOLS_GUIDE.md
```

### 1.3 Review Integration Examples

**Test**: Verify `docs/tool_combination_examples.md` quality

**Checklist**:
- [ ] Example 1: Architecture planning (Codicil + Jido AI)
- [ ] Example 2: Implementation coordination (Anubis MCP + Jido AI + Swarm Ex)
- [ ] Example 3: Code review (Codicil + mgrep + Jido AI)
- [ ] Example 4: Multi-language search (Probe + Codicil)
- [ ] Example 5: Advanced multi-agent orchestration (Jido AI + Swarm Ex + Anubis MCP + Codicil)
- [ ] Tool stack decision guide included
- [ ] Performance characteristics documented

**Validation Commands**:
```bash
# Count examples
grep "### Example" docs/tool_combination_examples.md | wc -l

# Check code examples
grep "```elixir\|```bash" docs/tool_combination_examples.md | wc -l
```

### 1.4 Review Migration Guide

**Test**: Verify `docs/migration_guide.md` completeness

**Checklist**:
- [ ] Arcana removal steps documented
- [ ] New tools integration steps documented
- [ ] Troubleshooting sections included for each phase
- [ ] Rollback plan documented
- [ ] Environment variable configuration documented
- [ ] Support resources listed

**Validation Commands**:
```bash
# Check Arcana removal section
grep -n "### Step 1: Remove Arcana" docs/migration_guide.md

# Verify rollback plan
grep -n "### 6.2 Rollback" docs/migration_guide.md
```

---

## Phase 2: Configuration Testing

### 2.1 Validate AGENTS.md Update

**Test**: Verify all 5 new tools are referenced in AGENTS.md

**Checklist**:
- [ ] Plan Mode tools section includes all 5 tools
- [ ] Build Mode tools section includes all 5 tools
- [ ] Review Mode tools section includes all 5 tools
- [ ] Tool usage patterns documented
- [ ] No outdated tool references (e.g., no Arcana mentions)

**Validation Commands**:
```bash
# Check for tool mentions in Plan Mode
grep -A 30 "### Plan Mode" AGENTS.md | grep -E "anubis_mcp|jido_ai|swarm_ex|codicil|probe"

# Check for tool mentions in Build Mode
grep -A 30 "### Build Mode" AGENTS.md | grep -E "anubis_mcp|jido_ai|swarm_ex|codicil|probe"

# Check for Arcana mentions (should be zero)
grep -i "arcana" AGENTS.md | wc -l
```

### 2.2 Validate MCP Configuration

**Test**: Verify `tools/opencode/opencode_mcp.json` includes all 5 tools

**Checklist**:
- [ ] anubis_mcp configured with correct command
- [ ] jido_ai configured with environment variables
- [ ] swarm_ex configured with environment variables
- [ ] codicil configured with environment variables
- [ ] probe configured with command and environment
- [ ] Old tools (hermes_custom, serena, tidewave) still present
- [ ] Token efficiency strategy set to "balanced"

**Validation Commands**:
```bash
# Check JSON validity
python3 -m json.tool tools/opencode/opencode_mcp.json

# Verify new tools present
jq '.mcp | keys' tools/opencode/opencode_mcp.json

# Check environment variables
jq '.mcp | to_entries | .[] | select(.key | contains("anubis_mcp|jido_ai|swarm_ex|codicil|probe")) | .value | .environment' tools/opencode/opencode_mcp.json
```

### 2.3 Validate Setup Scripts

**Test**: Run setup scripts and verify output

**Checklist**:
- [ ] `scripts/setup_new_tools.sh` runs without errors
- [ ] `scripts/setup_opencode.sh` calls new tools setup
- [ ] `scripts/validate_new_tools.sh` checks all tools
- [ ] Error messages are clear and actionable

**Validation Commands**:
```bash
# Run setup script
bash -x scripts/setup_new_tools.sh 2>&1 | tee /tmp/setup_output.log

# Run validation script
bash scripts/validate_new_tools.sh 2>&1 | tee /tmp/validate_output.log

# Check for errors
grep -E "ERROR|error|Error" /tmp/setup_output.log /tmp/validate_output.log
```

---

## Phase 3: Template Testing

### 3.1 Validate Mix Template

**Test**: Verify `templates/phoenix-ash-liveview/mix.exs.template` correctness

**Checklist**:
- [ ] All 5 new tools included in deps
- [ ] Correct version constraints
- [ ] Proper mix functions (deps, application)
- [ ] No syntax errors
- [ ] No LSP warnings

**Validation Commands**:
```bash
# Check template syntax
elixir -e "Code.string_to_quoted(File.read!(\"templates/phoenix-ash-liveview/mix.exs.template\"))" 2>&1

# Check for tool dependencies
grep -E "anubis_mcp|jido_ai|swarm_ex|codicil" templates/phoenix-ash-liveview/mix.exs.template

# Verify only flag for codicil
grep "codicil.*only:" templates/phoenix-ash-liveview/mix.exs.template
```

### 3.2 Validate Configuration Template

**Test**: Verify `templates/phoenix-ash-liveview/config/dev.exs.template` completeness

**Checklist**:
- [ ] Codicil configuration included
- [ ] Jido AI configuration included
- [ ] Swarm Ex configuration included
- [ ] Anubis MCP configuration included
- [ ] Environment variables use System.get_env()
- [ ] Code.ensure_loaded? guards present
- [ ] Credo configuration included

**Validation Commands**:
```bash
# Check for Codicil config
grep -A 10 "Codicil:" templates/phoenix-ash-liveview/config/dev.exs.template

# Check for Jido AI config
grep -A 20 "jido_ai:" templates/phoenix-ash-liveview/config/dev.exs.template

# Count environment variables
grep -c "System.get_env" templates/phoenix-ash-liveview/config/dev.exs.template
```

---

## Phase 4: Test Project Integration

### 4.1 Create Test Project

**Test**: Use test_project to validate all tools work together

**Checklist**:
- [ ] Initialize project from template
- [ ] Install dependencies
- [ ] Configure environment variables
- [ ] Verify all 5 tools are available
- [ ] Verify no Arcana references remain

**Validation Commands**:
```bash
# Navigate to test project
cd test_project

# Install dependencies
mix deps.get 2>&1 | tee /tmp/deps_get.log

# Compile and check for errors
mix compile 2>&1 | tee /tmp/compile.log

# Check loaded modules
iex -S mix -e "IO.inspect(Code.ensure_loaded?(Anubis.Server)); IO.inspect(Code.ensure_loaded?(Jido.AI)); IO.inspect(Code.ensure_loaded?(SwarmEx.Agent)); IO.inspect(Code.ensure_loaded?(Codicil))"
```

### 4.2 Test Tool Availability

**Test**: Verify each tool is accessible

**Checklist**:
- [ ] Anubis MCP server can be started
- [ ] Jido AI can create models
- [ ] Swarm Ex agents can be started
- [ ] Codicil can index code
- [ ] Probe MCP server is accessible via npx

**Validation Commands**:
```bash
# Test Anubis MCP
iex -S mix -e "Application.ensure_all_started()[:test_project] && IO.inspect(Anubis.Server.list_tools())"

# Test Jido AI
iex -S mix -e "Jido.AI.Model.from({:anthropic, [model: \"claude-3-5-sonnet\"]})"

# Test Swarm Ex
iex -S mix -e "SwarmEx.Agent.start_link(TestProject.Agents.Coordinator)"

# Test Codicil
mix codicil.setup 2>&1

# Test Probe
npx -y @buger/probe-mcp --help
```

---

## Phase 5: Integration Testing

### 5.1 Test Tool Combinations

**Test**: Verify tools can be used together

**Test Scenarios**:
1. **Codicil + Jido AI** - Code understanding with agent reasoning
2. **Anubis MCP + Jido AI** - Custom MCP server with agent framework
3. **Swarm Ex + Jido AI** - Agent orchestration with LLM integration
4. **Codicil + mgrep** - Cross-reference code patterns
5. **Probe + Codicil** - Multi-language + Elixir search

**Validation Commands**:
```bash
# Scenario 1: Codicil + Jido AI
# (Create test module and run)

# Scenario 2: Anubis MCP + Jido AI
# (Create test module and run)

# Scenario 3: Swarm Ex + Jodo AI
# (Create test module and run)

# Scenario 4: Codicil + mgrep
# (Run both and compare results)

# Scenario 5: Probe + Codicil
# (Run both on polyglot codebase)
```

---

## Phase 6: Documentation Completeness

### 6.1 Verify No Arcana References

**Test**: Ensure Arcana is completely removed

**Checklist**:
- [ ] No Arcana in AGENTS.md
- [ ] No Arcana in tools/README.md
- [ ] No Arcana in docs/MCP_COMPARISON.md (except removal note)
- [ ] No Arcana in tools/NEW_TOOLS_GUIDE.md
- [ ] No Arcana in docs/tool_combination_examples.md
- [ ] No Arcana in docs/migration_guide.md

**Validation Commands**:
```bash
# Search for Arcana references
grep -ri "arcana" . --include="*.md" | grep -v "migration_guide.md"

# Should only find references in migration_guide.md explaining removal
```

### 6.2 Verify Documentation Consistency

**Test**: Ensure all documentation is consistent

**Checklist**:
- [ ] All tool names use consistent casing (snake_case vs camelCase)
- [ ] All license references are accurate
- [ ] All version numbers are consistent
- [ ] All upstream repository URLs are correct

**Validation Commands**:
```bash
# Check tool name consistency
grep -r "anubis\|jido\|swarm\|codicil\|probe" skills/*/SKILL.md

# Check upstream repository URLs
grep -E "github\.com|hexdocs\.pm" skills/*/SKILL.md

# Verify no typos
aspell check skills/*/SKILL.md tools/NEW_TOOLS_GUIDE.md docs/tool_combination_examples.md
```

---

## Phase 7: Git Workflow Verification

### 7.1 Verify Git History

**Test**: Ensure proper git traceability

**Checklist**:
- [ ] All 9 commits have descriptive messages
- [ ] Commit messages follow conventional format (feat:, fix:, docs:)
- [ ] Commits are in logical order
- [ ] No merge commits without messages
- [ ] Branch is ahead of origin/main

**Validation Commands**:
```bash
# View commit history
git log --oneline -9

# Check for conventional format
git log --oneline -9 | grep -vE "^feat:|^fix:|^docs:"

# Verify branch status
git status
```

### 7.2 Verify Files Committed

**Test**: Ensure all created files are committed

**Checklist**:
- [ ] All SKILL.md files committed (5 files)
- [ ] All documentation files committed (3 files)
- [ ] All scripts committed (3 files)
- [ ] All template files committed (3 files)
- [ ] Test project committed
- [ ] No untracked files (except test_project/)

**Validation Commands**:
```bash
# List all untracked files
git ls-files --others --exclude-standard

# Should show minimal output
```

---

## Test Execution Plan

### Sequential Testing Order

1. **Run validation script**
   ```bash
   bash scripts/validate_new_tools.sh
   ```

2. **Check LSP warnings**
   ```bash
   cd test_project
   mix compile 2>&1 | grep -E "warning|error"
   ```

3. **Verify environment variables**
   ```bash
   env | grep -E "ANTHROPIC|OPENAI|GOOGLE|CODICIL|JIDO"
   ```

4. **Test project initialization**
   ```bash
   cd test_project
   mix deps.get
   mix compile
   ```

5. **Test individual tools**
   ```bash
   # Test Codicil
   mix codicil.setup
   
   # Test Jido AI
   iex -S mix -e "Jido.AI.Model.from({:anthropic, []})"
   
   # Test Swarm Ex
   iex -S mix -e "SwarmEx.Agent.start_link(Start)"
   ```

6. **Test tool combinations**
   - Run examples from `docs/tool_combination_examples.md`

---

## Success Criteria

### Phase 1: Documentation
- ✅ All 5 SKILL.md files complete with comprehensive examples
- ✅ Tools comparison guide accurate and complete
- ✅ Integration examples cover all 5 tools
- ✅ Migration guide step-by-step and clear

### Phase 2: Configuration
- ✅ AGENTS.md includes all 5 tools
- ✅ MCP configuration includes all 5 tools with correct settings
- ✅ Setup scripts run without errors

### Phase 3: Templates
- ✅ Mix template includes all 5 tools with correct versions
- ✅ Configuration template includes all 5 tools with proper guards

### Phase 4: Integration
- ✅ Test project compiles without errors
- ✅ All 5 tools are accessible in test project
- ✅ Tools can be used together in combinations

### Phase 5: Documentation Completeness
- ✅ No Arcana references remain (except removal note)
- ✅ Documentation is consistent across all files
- ✅ Upstream repository URLs are correct

### Phase 6: Git Workflow
- ✅ All commits follow conventional format
- ✅ Proper git traceability maintained
- ✅ Branch is clean and ready to push

---

## Issue Tracking

### Document Issues Found

| Issue | Phase | Severity | Status |
|-------|--------|----------|--------|
| LSP warnings in test project | Template | Low | Known, not critical |
| Elixir version detection in validation script | Script | Medium | Fixed in commit 696c89b |

---

## Test Results Log

### Date: January 16, 2026
### Tester: [Your Name]

#### Run 1: Validation Script
**Status**: ⏸ Pending
**Output**: (To be filled)
**Issues**: (To be filled)

#### Run 2: LSP Check
**Status**: ⏸ Pending
**Output**: (To be filled)
**Issues**: LSP warnings in application.ex (known, not blocking)

#### Run 3: Environment Variables
**Status**: ⏸ Pending
**Output**: (To be filled)
**Issues**: (To be filled)

#### Run 4: Project Initialization
**Status**: ⏸ Pending
**Output**: (To be filled)
**Issues**: (To be filled)

#### Run 5: Tool Testing
**Status**: ⏸ Pending
**Output**: (To be filled)
**Issues**: (To be filled)

#### Run 6: Tool Combinations
**Status**: ⏸ Pending
**Output**: (To be filled)
**Issues**: (To be filled)

---

## Recommendations

### For Testing
1. Start with validation script to ensure tools are set up
2. Test each tool individually before testing combinations
3. Use test_project as controlled environment
4. Document any issues found during testing
5. Update migration guide based on testing feedback

### For Documentation
1. Consider adding video tutorials for complex tool combinations
2. Add real-world examples from actual projects
3. Create troubleshooting FAQ based on testing

### For Future Enhancements
1. Consider adding automated tests for tool integration
2. Add CI/CD for validating tool configurations
3. Create example projects for each tool combination

---

**Last Updated**: January 16, 2026
**Version**: 1.0.0
