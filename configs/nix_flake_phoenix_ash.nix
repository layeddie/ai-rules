{
  description = "Phoenix + Ash Web Development Environment";

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
              inotify-tools
            ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
              CoreFoundation
              CoreServices
            ]) ++ lib.optionals stdenv.isDarwin [
              fswatch
            ];

            shellHook = ''
              mkdir -p .nix-mix .nix-hex
              export MIX_HOME=$PWD/.nix-mix
              export HEX_HOME=$PWD/.nix-hex
              export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
              export ERL_AFLAGS="-kernel shell_history enabled"

              echo "----------------------------------------------------------------"
              echo "🔥 Phoenix + Ash Development Environment Loaded"
              echo "   Platform: ${if pkgs.stdenv.isDarwin then "macOS" else "Linux"}"
              echo "   Elixir Version: $(elixir --version | grep Elixir | awk '{print $2}')"
              echo "   Erlang/OTP: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)"
              echo "   PostgreSQL: $(psql --version | head -1 | awk '{print $3}')"
              echo "   Node.js: $(node --version)"
              echo "----------------------------------------------------------------"
              echo ""
              echo "📦 Available commands:"
              echo "   mix deps.get             - Install Elixir dependencies"
              echo "   mix test                - Run tests"
              echo "   mix compile             - Compile project"
              echo "   mix format              - Format code"
              echo "   mix credo               - Code analysis"
              echo "   mix dialyzer            - Type checking"
              echo "   mix phx.server          - Start Phoenix server (default: http://localhost:4000)"
              echo "   mix phx.gen.resource    - Generate Phoenix resource"
              echo "   mix ash.gen.resource     - Generate Ash resource"
              echo "   psql                    - PostgreSQL CLI (start with: postgres -D $PWD/db)"
              echo "   npm install              - Install Phoenix asset dependencies"
              echo "   npm run dev             - Watch and compile assets"
              echo "----------------------------------------------------------------"
              echo ""
              echo "💡 Ash Framework Tips:"
              echo "   - Add Ash formatter to .formatter.exs: import_deps: [:ash]"
              echo "   - Use Igniter for project setup: mix igniter.install ash"
              echo "   - Create Ash API: use Ash.Api, do [resources...] end"
              echo "   - Create Ash Resource: use Ash.Resource, do [...] end"
              echo "----------------------------------------------------------------"
              echo ""

              export MIX_ENV="dev"

              # Phoenix LiveView hot reload
              if [ "${if pkgs.stdenv.isDarwin then "true" else "false"}" = "true" ]; then
                export CHOKIDAR_USEPOLLING="true"
              fi

              # PostgreSQL (uncomment to auto-start)
              # export PGDATA="$PWD/db"
              # export PGHOST="$PWD"
              # echo "📊 PostgreSQL: Run 'postgres -D $PGDATA' to start server"

              # Phoenix environment variables (set these in .env or .env.local)
              # export PHX_SERVER="true"
              # export SECRET_KEY_BASE="generate with: mix phx.gen.secret"
              # export DATABASE_URL="postgresql://postgres:postgres@localhost/my_app_dev"

              # Ash environment variables
              # export ASH_API_DOMAIN="true"

              # Local LLM paths (optional - uncomment if using)
              # export OLLAMA_HOST="http://localhost:11434"
              # export LMSTUDIO_HOST="http://localhost:1234/v1"
            '';
          };
        }
    );
}
