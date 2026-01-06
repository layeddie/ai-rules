{
  description = "Nerves Embedded Systems Development Environment";

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
              fwup
              squashfsTools
              autoconf
              automake
              curl
              x11_ssh_askpass
              postgresql_16
            ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
              CoreFoundation
              CoreServices
            ]);

            shellHook = ''
              mkdir -p .nix-mix .nix-hex
              export MIX_HOME=$PWD/.nix-mix
              export HEX_HOME=$PWD/.nix-hex
              export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
              export ERL_AFLAGS="-kernel shell_history enabled"

              echo "----------------------------------------------------------------"
              echo "🔌 Nerves Embedded Systems Environment Loaded"
              echo "   Platform: ${if pkgs.stdenv.isDarwin then "macOS" else "Linux"}"
              echo "   Elixir Version: $(elixir --version | grep Elixir | awk '{print $2}')"
              echo "   Erlang/OTP: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)"
              echo "   fwup: $(fwup --version | awk '{print $2}')"
              echo "   PostgreSQL: $(psql --version | head -1 | awk '{print $3}')"
              echo "----------------------------------------------------------------"
              echo ""
              echo "📦 Available commands:"
              echo "   mix deps.get             - Install Elixir dependencies"
              echo "   mix test                - Run tests"
              echo "   mix compile             - Compile project"
              echo "   mix format              - Format code"
              echo "   mix firmware            - Build firmware image"
              echo "   mix firmware.burn        - Flash firmware to SD card"
              echo "   mix nerves.bootstrap       - Bootstrap Nerves system"
              echo "   mix nerves.new           - Create new Nerves project"
              echo "   psql                    - PostgreSQL CLI"
              echo "----------------------------------------------------------------"
              echo ""
              echo "💡 Nerves Tips:"
              echo "   - First time? Run: mix archive.install hex nerves_bootstrap"
              echo "   - Create project: mix nerves.new my_nerves_app"
              echo "   - Burn firmware: SUDO_ASKPASS=$(which ssh-askpass) mix firmware.burn"
              echo "   - Cross-compile: export MIX_TARGET=triplet (e.g., rpi3, bbb)"
              echo "----------------------------------------------------------------"
              echo ""

              export MIX_ENV="dev"

              # Firmware burning password helper
              export SUDO_ASKPASS=${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass

              # Cross-compilation targets (uncomment to use)
              # export MIX_TARGET="rpi3"          # Raspberry Pi 3
              # export MIX_TARGET="rpi4"          # Raspberry Pi 4
              # export MIX_TARGET="bbb"            # BeagleBone Black
              # export MIX_TARGET="x86_64"         # Generic x86_64
              # export MIX_TARGET="rpi0"          # Raspberry Pi Zero
              # export MIX_TARGET="x86_64_unknown_linux_musl"  # Alpine Linux

              # Nerves-specific environment
              # export NERVES_SYSTEM="nerves_system_rpi3"
              # export NERVES_ENV="prod"

              # PostgreSQL for testing Nerves applications
              # export PGDATA="$PWD/db"
              # export PGHOST="$PWD"

              # Local LLM paths (optional - uncomment if using)
              # export OLLAMA_HOST="http://localhost:11434"
              # export LMSTUDIO_HOST="http://localhost:1234/v1"
            '';
          };
        }
    );
}
