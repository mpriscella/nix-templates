{
  description = "Reusable Nix flake templates for project development environments.";

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
          packages = with pkgs; [];

          # Set any environment variables for your development environment.
          env = {};

          # Add any shell logic you want executed when the environment is
          # activated.
          shellHook = "";
        };
      }
    );

    templates = {
      default = {
        path = ./templates/default;
        description = "A minimal Nix flake template for reproducible multi-system builds and dev environments.";
      };
      laravel = {
        path = ./templates/laravel;
        description = "Dev environment for a Laravel application or package; scaffolds a fresh app if none exists.";
      };
      zig = {
        path = ./templates/zig;
        description = "Dev environment for a Zig project with the toolchain pinned via zig-overlay.";
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
