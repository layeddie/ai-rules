I dont have auth for hex yet - i think i need to run through how to use ai_rules_agent first and see what it does in an elixir project. that includes using ai_rules symlinked into an elixir project or how do I combine the benefits of both when developing an elixir / phoenix project

Understood—skip Hex publish for now and dogfood locally. Two ways to use it in an Elixir/Phoenix project:

1. Git dependency (simple)
   In your project’s mix.exs:

defp deps do
[
{:ai_rules_agent, git: "https://github.com/layeddie/ai_rules_agent.git", branch: "main"}
]
end
Then mix deps.get.

2. Path dependency (fast local edits)
   Clone the new repo alongside your project and point to it:

defp deps do
[
{:ai_rules_agent, path: "../ai_rules_agent"}
]
end
Then mix deps.get.

Using alongside ai_rules (playbook)

Keep the ai_rules repo for docs/policies/workflows.
In your app, add ai_rules_agent as dep (path or git).
Optional: copy ai/ scaffold (allowlist, prompts) from ai_rules_agent templates or from your existing ai_rules repo.
Quick integration steps in a Phoenix app

Add dep (path or git).
Configure provider keys in dev.exs, e.g.:
config :ai_rules_agent, :providers,
default_model: "gpt-4o"
Start an agent:
llm_fun = AiRulesAgent.Transports.OpenAI.llm_fun(model: "gpt-4o", api_key: System.fetch_env!("OPENAI_API_KEY"))
tools = %{"fetch" => AiRulesAgent.Tools.WebFetch.spec()}
{:ok, pid} = AiRulesAgent.AgentServer.start_link(strategy: AiRulesAgent.Strategies.ReAct, llm_fun: llm_fun, tools: tools)
AiRulesAgent.AgentServer.ask(pid, "Fetch https://example.com")
Or run the HTTP/stdio lifecycle servers from the package templates to manage agents externally.
When ready to publish

Stick with path/git dep while iterating.
Once comfortable, get a Hex account (mix hex.user register), then tag/publish.
If you want, I can add a short “Using in your project” section to ai_rules_agent README to capture this.

Here’s a concise tag/release checklist for the new ai_rules_agent repo:

Clone/switch to new repo

git clone git@github.com:layeddie/ai_rules_agent.git
cd ai_rules_agent
Ensure clean tree

Remove artifacts (if any): rm -rf \_build deps priv .nix-mix .nix-hex
git status should be clean.
Install deps & run CI locally

mix deps.get
mix ci # format --check, credo --strict, test
Tag the release

git tag v0.1.0-beta
git push origin v0.1.0-beta
Publish to Hex (when ready)

Register/login if needed: mix hex.user register (once)
Publish: mix hex.publish
Confirm on hex.pm.
Update main repo (if using package)

In ai-rules (or other apps), add dep:
{:ai_rules_agent, "~> 0.1.0-beta"}
Or pin to git:
{:ai_rules_agent, git: "https://github.com/layeddie/ai_rules_agent.git", tag: "v0.1.0-beta"}
CI/Dependabot

Already present (ci.yml, dependabot.yml). Verify GitHub Actions runs green after push.
Docs/Changelog

Update CHANGELOG.md with release notes (already has “Unreleased”).
README is current with usage steps.
Optional safety:

Run mix hex.build to verify the package before publish.
If you want a signed tag: git tag -s v0.1.0-beta -m "v0.1.0-beta".
That’s it—execute those steps in the new repo when you’re ready to release.
