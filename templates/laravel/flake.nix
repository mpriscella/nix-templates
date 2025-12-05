{
  description = "Dev environment for a Laravel application or package.
  Scaffolds a fresh app if the directory doesn't contain one yet.";

  inputs = {
    nixpkgs = {
      url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    };
  };

  outputs = {self, ...} @ inputs: let
    # The systems supported for this flake's outputs.
    supportedSystems = [
      "x86_64-linux" # 64-bit Intel/AMD Linux.
      "aarch64-linux" # 64-bit ARM Linux.
      "x86_64-darwin" # 64-bit Intel macOS.
      "aarch64-darwin" # 64-bit ARM macOS.
    ];

    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            # Provides a system-specific, configured Nixpkgs.
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
      );
  in {
    # The default formatter for this flake.
    formatter = forEachSupportedSystem (
      {pkgs}: pkgs.alejandra
    );

    devShells = forEachSupportedSystem (
      {pkgs}: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # Pin the PHP version the project targets explicitly (php83,
            # php84, ...) so upgrading nixpkgs never changes it silently.
            # Extensions live on the package: php84.withExtensions or
            # `php84.buildEnv { extraConfig = ...; }` for ini tweaks.
            php84
            php84Packages.composer

            # The Laravel installer, used by the scaffolding below.
            laravel

            # Vite / asset tooling used by the Laravel starter kits.
            nodejs_24
          ];

          # Set any environment variables for your development environment.
          env = {};

          # Scaffold a new application on first entry. The artisan check
          # keeps this a no-op in existing apps and packages.
          shellHook = ''
            if [[ ! -e "artisan" ]]; then
              laravel new tmp --database=sqlite --pest --npm --no-interaction
              mv tmp/* .
              mv tmp/.* . 2>/dev/null || true
              rm -rf tmp
            fi
          '';
        };
      }
    );

    # Default checks for this flake.
    checks = forEachSupportedSystem (
      {pkgs}: {
        # Format check using alejandra.
        format = pkgs.runCommand "check-format" {} ''
          ${pkgs.alejandra}/bin/alejandra --check ${./.}
          touch $out
        '';

        # Build check for the development shell.
        build-devshell = self.devShells.${pkgs.system}.default;
      }
    );
  };
}
