# Needs to install:
# - npm
# - wp-env npm package https://www.npmjs.com/package/@wordpress/env
# Will use a docker container for the MySQL server
{
  description = "A Nix Flake to create a quick WordPress development environment";

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
            echo "WP Development Environment"
            echo ""
            echo "IMPORTANT: Make sure to run npm install"
            echo ""
            echo "Common wp-env commands:"
            echo "  wp-env start                  # Build and start the containers"
            echo "  wp-env stop                   # Stop the containers"
            echo "  wp-env destroy                # Remove containers and volumes"
            echo "  wp-env logs                   # Show container logs"
            echo "  wp-env run cli wp <command>   # Run WP-CLI inside the WordPress container"
          '';
        };
      }
    );

    templates = {
      wordpress = {
        path = ./templates/wordpress;
        description = "A minimal Wordpress development environment.";
      };
    };

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
