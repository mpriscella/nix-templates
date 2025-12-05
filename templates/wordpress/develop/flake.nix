{
  description = "Bootstraps a WordPress core development setup.";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
          # The Nix packages provided in the environment.
          packages = with pkgs; [
            nodejs_24
            php
            php84Packages.composer
          ];

          # Set any environment variables for your development environment.
          env = {};

          # Add any shell logic you want executed when the environment is
          # activated.
          shellHook = ''
            if [[ ! -e "wp-config.php" ]]; then
              git clone https://github.com/WordPress/wordpress-develop.git --depth 1 tmp
              mv tmp/* .
              mv tmp/.* .
              rm -rf tmp
              rm -rf .git
            fi
            echo "Run the following commands:"
            echo "  \$ npm install"
            echo "  \$ npm run env:start     # Starts the environment"
            echo "  \$ npm run env:install   # Installs the environment"
            echo "  \$ npm run dev           # Builds the website and watches for changes"
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
