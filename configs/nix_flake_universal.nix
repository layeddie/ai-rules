{
  description = "Universal Elixir Development Environment (Elixir, Phoenix, LiveView, Ash, Livebook, PostgreSQL)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        erlang = final.beam.interpreters.erlang_27;
        pkgs-beam = final.beam.packagesWith final.erlang;
        elixir = final.pkgs-beam.elixir_1_17;
      };
    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              elixir
              erlang
              git
              postgresql_16
              nodejs_20
              pkg-config
              openssl
            ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
              CoreFoundation
              CoreServices
            ]) ++ lib.optionals stdenv.isDarwin [
              fswatch
            ] ++ lib.optionals stdenv.isLinux [
              inotify-tools
            ];

            shellHook = ''
              mkdir -p .nix-mix .nix-hex
              export MIX_HOME=$PWD/.nix-mix
              export HEX_HOME=$PWD/.nix-hex
              export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
              export ERL_AFLAGS="-kernel shell_history enabled"

              echo "----------------------------------------------------------------"
              echo "🧪 Universal Elixir Environment Loaded"
              echo "   Platform: ${if pkgs.stdenv.isDarwin then "macOS" else "Linux"}"
              echo "   Elixir Version: $(elixir --version | grep Elixir | awk '{print $2}')"
              echo "   Erlang/OTP: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)"
              echo "   PostgreSQL: $(psql --version | head -1 | awk '{print $3}')"
              echo "   Node.js: $(node --version)"
              echo "----------------------------------------------------------------"
              echo ""
              echo "📦 Available commands:"
              echo "   mix deps.get       - Install Elixir dependencies"
              echo "   mix test          - Run tests"
              echo "   mix compile       - Compile project"
              echo "   mix format        - Format code"
              echo "   mix credo         - Code analysis"
              echo "   mix dialyzer      - Type checking"
              echo "   psql              - PostgreSQL CLI (local server: postgres start)"
              echo "   npm install       - Install Phoenix asset dependencies"
              echo "   mix phx.server    - Start Phoenix server"
              echo "   mix livebook      - Start Livebook server"
              echo "----------------------------------------------------------------"
              echo ""

              export MIX_ENV="dev"

              # Local LLM paths (optional - uncomment if using)
              # export OLLAMA_HOST="http://localhost:11434"
              # export LMSTUDIO_HOST="http://localhost:1234/v1"
            '';
          };
        }
    );
}
