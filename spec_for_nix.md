


## Update our nix strategy for ai-rules
Nix flakes are our preferred method for creating dev shells for our elixir projects.

Add nix and nixos md files to /Users/elay14/projects/2026/ai-rules/tools/nixos folder. 
Always use git_rules.md - so that we can track our changes

I want this folder to provide AI with all the information it needs to create flake.nix files suitable for elixir local development. Create an elixir_flakes.md file with examples flake.nix files suitable for creating elixir, nerves, gleam, rust, phoenix / ash / liveview projects.


I use determinate nix and direnv on my macbook. 
plus I have orbstack installed for runnning nixos locally in a VM / container or kubernetes 
We should use nix containers to build our dve shells too


we already have some good examples in /Users/elay14/projects/2026/ai-rules/configs - the universal flake is pretty good. 
we need to consider using nix templates too...

 These 2 files can be used as examples but they are out of date   /Users/elay14/projects/2026/ai-rules/scripts/init_project.sh and /Users/elay14/projects/2026/ai-rules/PROJECT_INIT.md - we need to leave these and create a new versions that reflect our agnostic llm use too.

Plan / Research any other links that will help and create a summary of what you find so that we can decide what finally will end up in /Users/elay14/projects/2026/ai-rules/tools/nixos/elixir_flakes.md
  


## The basic steps in init_project.sh are... 

1. choose project language and versions 
2. choose nix template 
3. create a nix shell with symlink to ai-rules 
4. run mix project command in nix shell


## These are some useful links - add these links into elixir_flakes.md

https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix
https://github.com/akirak/flake-templates - 

I have this repo stored locally at /Users/elay14/projects/2026/flake-templates - also at https://github.com/the-nix-way/dev-templates/blob/main/elixir/flake.nix.

https://nur.nix-community.org/ - https://github.com/liyangau/flake-templates
https://www.youtube.com/watch?v=_8xh5EcsHr

https://tech.aufomm.com/my-nix-journey-how-to-use-nix-to-set-up-dev-environment/

https://github.com/nixops4/nixops4
https://github.com/nixops4/nixops4-nixos/tree/main/example - https://github.com/the-nix-way/dev-templates/blob/main/elixir/flake.nix
https://tech.aufomm.com/my-nixos-journey-flakes/
https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/ - https://nixos.wiki/wiki/NixOS_Containers 
