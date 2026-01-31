#!/usr/bin/env elixir

defmodule BuildPatternIndex do
  @moduledoc """
  Automated PATTERN_INDEX.md generator for Elixir pattern files.
  """

  @patterns_dir __DIR__
  @extracted_dir Path.join(@patterns_dir, "extracted_data")
  @output_file Path.join(@patterns_dir, "PATTERN_INDEX.md")

  def run do
    IO.puts("=== Elixir Pattern Index Builder ===")
    IO.puts("Scanning: #{@extracted_dir}")
    IO.puts("Output: #{@output_file}")
    IO.puts("")

    pattern_files = discover_pattern_files()
    IO.puts("Found #{length(pattern_files)} pattern files")

    extracted_data = extract_pattern_data(pattern_files)
    IO.puts("Extracted #{count_patterns(extracted_data)} patterns")

    mappings = build_keyword_mappings(extracted_data)
    IO.puts("Generated #{length(mappings)} keyword mappings")

    index_content = generate_index_content(extracted_data, mappings)
    write_index(index_content)

    validate_output(extracted_data, index_content)

    display_summary(extracted_data, mappings)
  end

  defp discover_pattern_files do
    File.ls!(@extracted_dir)
    |> Enum.filter(&String.ends_with?(&1, "_patterns.txt"))
    |> Enum.map(&Path.join(@extracted_dir, &1))
  end

  defp extract_pattern_data(files) do
    files
    |> Enum.map(fn file ->
      content = File.read!(file)
      filename = Path.basename(file, "_patterns.txt")

      %{
        file: filename <> ".md",
        patterns: extract_patterns(content)
      }
    end)
  end

  defp extract_patterns(content) do
    # Parse the extracted format
    PatternParser.parse_file(content)
  end

  defp build_keyword_mappings(extracted_data) do
    extracted_data
    |> Enum.flat_map(fn file_data ->
      file_data.patterns
      |> Enum.map(fn pattern ->
        keywords = generate_keywords(pattern)

        %{
          keywords: Enum.join(keywords, ", "),
          pattern_file: file_data.file,
          section: "Pattern #{pattern.number}",
          title: pattern.title
        }
      end)
    end)
    |> Enum.take(50)  # Limit to top 50 mappings for 2K token target
  end

  defp generate_keywords(pattern) do
    # Extract keywords from title, problem, concept
    title_keywords = extract_keywords(pattern.title)
    problem_keywords = extract_keywords(pattern.problem || "")
    concept_keywords = extract_keywords(pattern.concept || "")

    # Prioritize: title > problem > concept
    keywords = title_keywords ++ problem_keywords ++ concept_keywords

    # Add file-specific common terms
    base_keywords = base_keywords_for_file(pattern.title)

    # Limit to top 6 most important keywords to reduce token count
    (base_keywords ++ keywords)
    |> Enum.uniq()
    |> Enum.filter(&(&1 != ""))
    |> Enum.filter(fn kw ->
      String.length(kw) >= 3 and
      not String.starts_with?(kw, "[") and
      not String.starts_with?(kw, "vs") and
      not String.starts_with?(kw, "with")
    end)
    |> Enum.take(6)
  end

  defp base_keywords_for_file(title) do
    cond do
      String.contains?(title, "GenServer") -> ["GenServer", "state", "process"]
      String.contains?(title, "LiveView") -> ["LiveView", "Phoenix", "web", "UI", "realtime"]
      String.contains?(title, "Phoenix") -> ["Phoenix", "controller", "web", "API"]
      String.contains?(title, "Ash") -> ["Ash", "resources", "domain-driven"]
      String.contains?(title, "Error") -> ["error", "handling", "exception"]
      String.contains?(title, "OTP") -> ["OTP", "supervisor", "restart"]
      String.contains?(title, "Testing") -> ["testing", "ExUnit", "test"]
      String.contains?(title, "Performance") -> ["performance", "optimization", "speed"]
      String.contains?(title, "Concurrency") -> ["concurrency", "Task", "Agent", "async"]
      String.contains?(title, "Caching") -> ["caching", "cache", "ETS"]
      String.contains?(title, "Retry") -> ["retry", "backoff", "transient"]
      String.contains?(title, "Bulkhead") -> ["bulkhead", "pool", "limit", "isolation"]
      String.contains?(title, "Graceful") -> ["graceful", "degradation", "fallback", "load"]
      String.contains?(title, "Ecto") -> ["Ecto", "migration", "database"]
      String.contains?(title, "Nerves") -> ["Nerves", "embedded", "firmware"]
      true -> []
    end
  end

  defp extract_keywords(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, " ")
    |> String.split(~r/\s+/)
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
    |> Enum.filter(fn kw ->
      String.length(kw) >= 3 and
      !Enum.member?(
        ["the", "and", "for", "with", "use", "from", "call", "make", "case", "when", "need", "this", "that", "your", "more", "how", "you", "all"],
        kw
      )
    end)
  end

  defp generate_index_content(extracted_data, mappings) do
    """
# Elixir Pattern Lookup Index

## How to Use This Index

1. Search for your problem in the Quick Problem Search table
2. Load the specified pattern file and section
3. Each pattern includes code examples ready to copy

## Quick Problem Search

| Problem Keywords | Pattern File | Section |
|---------------|--------------|---------|
#{format_mappings_table(mappings)}

## Pattern File Directory

#{format_pattern_directory(extracted_data)}

## Cross-Reference Map

| Problem | Primary Pattern | Related Patterns |
|---------|----------------|------------------|
#{format_cross_references(extracted_data)}

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

**Last Updated**: #{DateTime.utc_now() |> NaiveDateTime.to_string() |> String.slice(0, 10)}
**Total Pattern Files**: #{length(extracted_data)}
**Total Patterns**: #{count_patterns(extracted_data)}
**Total Keyword Mappings**: #{length(mappings)}

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
    """
  end

  defp format_mappings_table(mappings) do
    mappings
    |> Enum.map(fn mapping ->
      "| #{mapping.keywords} | #{mapping.pattern_file} | #{mapping.section} |"
    end)
    |> Enum.join("\n")
  end

  defp format_pattern_directory(extracted_data) do
    # Categorize files
    state_management = ["genserver.md", "ets_performance.md", "concurrent_tasks.md"]
    web_patterns = ["liveview.md", "phoenix_controllers.md"]
    ash_framework = ["ash_resources.md", "migration_strategies.md"]
    otp_supervision = ["otp_supervisor.md"]
    error_handling = ["error_handling.md"]
    testing = ["exunit_testing.md"]
    resilience = ["retry_strategies.md", "bulkhead_patterns.md", "graceful_degradation.md"]
    embedded = ["nerves_firmware.md"]

    sections = %{
      "### State Management" => state_management,
      "### Web Patterns" => web_patterns,
      "### Ash Framework" => ash_framework,
      "### OTP/Supervision" => otp_supervision,
      "### Error Handling" => error_handling,
      "### Testing" => testing,
      "### Resilience" => resilience,
      "### Embedded Systems" => embedded
    }

    sections
    |> Enum.map(fn {header, files} ->
      files_data = Enum.filter(extracted_data, fn fd -> fd.file in files end)

      """
#{header}

#{ Enum.map(files_data, &format_file_entry(&1)) |> Enum.join("\n\n")}
      """
    end)
    |> Enum.join("\n\n")
  end

  defp format_file_entry(file_data) do
    filename = file_data.file
    count = length(file_data.patterns)

    top_patterns =
      file_data.patterns
      |> Enum.take(2)
      |> Enum.map(fn pattern ->
        "- #{String.slice(pattern.title, 0, 40)} → P#{pattern.number}"
      end)
      |> Enum.join("\n")

    """
**#{filename}** (#{count} patterns)
#{top_patterns}
    """
  end

defp format_cross_references(extracted_data) do
    # Simplified cross-references - top tier patterns only
    refs = [
      {"Concurrent state", "genserver.md", "ets, concurrent, otp"},
      {"Web UI performance", "liveview.md", "phoenix, tasks, ets"},
      {"Fault-tolerant", "otp_supervisor.md", "genserver, errors, degradation"},
      {"Resilience", "retry_strategies.md", "bulkhead, degradation"},
      {"Database", "ash_resources.md", "migration, ecto"},
      {"Error handling", "error_handling.md", "exunit, genserver"},
      {"Testing", "exunit_testing.md", "errors, liveview"},
      {"Performance", "ets_performance.md", "genserver, tasks"},
      {"Caching", "ets_performance.md", "tasks, degradation"}
    ]

    refs
    |> Enum.map(fn {problem, primary, related} ->
      "| #{problem} | #{primary} | #{related} |"
    end)
    |> Enum.join("\n")
  end

  defp write_index(content) do
    File.write!(@output_file, content, [:binary])
    IO.puts("✅ Wrote: #{@output_file}")
  end

  defp validate_output(extracted_data, content) do
    file_count = length(extracted_data)
    expected_files = 14

    IO.puts("")
    IO.puts("=== Validation ===")
    IO.puts("Pattern Files: #{file_count}/#{expected_files}")

    if file_count == expected_files do
      IO.puts("✅ Found all expected pattern files")
    else
      IO.puts("⚠️  Missing or extra files")
    end

    # Token count check
    char_count = String.length(content)
    token_estimate = char_count / 4  # Rough estimate: 4 chars per token
    target_tokens = 2000

    IO.puts("Character count: #{char_count}")
    IO.puts("Estimated tokens: #{trunc(token_estimate)}")
    IO.puts("Target tokens: #{target_tokens}")

    if abs(token_estimate - target_tokens) < target_tokens * 0.1 do
      IO.puts("✅ Token count within 10% of target")
    else
      IO.puts("⚠️  Token count outside target range")
    end
  end

  defp count_patterns(extracted_data) do
    extracted_data |> Enum.flat_map(& &1.patterns) |> length()
  end

  defp display_summary(extracted_data, mappings) do
    IO.puts("")
    IO.puts("=== Summary ===")
    IO.puts("Pattern Files: #{length(extracted_data)}")
    IO.puts("Total Patterns: #{count_patterns(extracted_data)}")
    IO.puts("Keyword Mappings: #{length(mappings)}")
    IO.puts("")
    IO.puts("✅ Index generation complete!")
  end
end

# Pattern parser module
defmodule PatternParser do
  def parse_file(content) do
    # Skip header lines
    content
    |> String.split("\n")
    |> Enum.drop_while(&String.starts_with?(&1, "# Pattern Extractor"))
    |> Enum.join("\n")
    |> String.split("---")
    |> Enum.filter(&String.contains?(&1, "## Pattern "))
    |> Enum.map(&parse_pattern/1)
  end

  defp parse_pattern(section) do
    section = String.trim(section)
    lines = String.split(section, "\n", trim: true)

    # Find the pattern header (first line starting with "## Pattern ")
    pattern_header_idx = Enum.find_index(lines, &String.starts_with?(&1, "## Pattern "))

    if is_nil(pattern_header_idx) do
      IO.puts("Warning: Could not find pattern header")
      %{
        number: 0,
        title: "Unknown Pattern",
        problem: "",
        concept: ""
      }
    else
      header = Enum.at(lines, pattern_header_idx)
      {number, title} = parse_header(header)

      # Get remaining lines for problem/concept
      rest = Enum.drop(lines, pattern_header_idx + 1)
      {problem, concept} = parse_details(rest)

      %{
        number: number,
        title: title,
        problem: problem,
        concept: concept
      }
    end
  end

  defp parse_header(header) do
    # Format: "## Pattern N: Title"
    case Regex.run(~r/## Pattern (\d+): (.+)/, header) do
      [_, num_str, title] ->
        number = String.to_integer(num_str)
        {number, String.trim(title)}
      _ ->
        {0, ""}
    end
  end

  defp parse_details(lines) do
    problem = find_line(lines, "PROBLEM:")
    concept = find_line(lines, "CONCEPT:")

    # Clean up the markers
    problem = if problem, do: String.replace(problem, "PROBLEM:", ""), else: nil
    concept = if concept, do: String.replace(concept, "CONCEPT:", ""), else: nil

    {String.trim(problem || ""), String.trim(concept || "")}
  end

  defp find_line(lines, prefix) do
    Enum.find(lines, fn line ->
      String.starts_with?(String.trim(line), prefix)
    end)
  end
end

# Run the generator
BuildPatternIndex.run()