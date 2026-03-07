# NixOS / Nix Tooling

This directory is the canonical home for ai-rules Nix configuration and guides.
examples:
https://beamops.co.uk/blog/reproducible-dev-shells
https://github.com/jurraca/elixir-templates/blob/main/README.md
https://nix.dev/
https://github.com/Zurga/phoenix_nix

## Flake Templates

- `tools/nixos/flakes/universal.nix`
- `tools/nixos/flakes/phoenix_ash.nix`
- `tools/nixos/flakes/nerves.nix`
- `tools/nixos/flakes/with_expert.nix`

## Usage

Copy a template into your project root as `flake.nix`:

```bash
cp ai-rules/tools/nixos/flakes/universal.nix flake.nix
```

Then choose a shell attribute:

```bash
# default
nix develop .#elixir_1_17_erlang_27

# Arcana-compatible
nix develop .#elixir_1_18_erlang_27
```
