{
  description = "Dev environment for a Zig project with a flake-pinned toolchain.";

  inputs = {
    nixpkgs = {
      url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    };

    # Mirrors the official Zig release binaries (no source builds).
    # Provides tagged releases (`packages.<system>."0.16.0"`), nightlies
    # (`.master`, `.master-<date>`), and `default` (latest tagged release).
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
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
            inherit system;
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
      {pkgs, ...}: pkgs.alejandra
    );

    devShells = forEachSupportedSystem (
      {
        pkgs,
        system,
      }: {
        default = pkgs.mkShell {
          packages = [
            # Pin the exact compiler the project targets, e.g.
            # `inputs.zig-overlay.packages.${system}."0.16.0"`. `default` is
            # the latest tagged release.
            #
            # zls must match the compiler's version. nixpkgs' zls tracks the
            # latest stable Zig, so this pairing works for tagged releases;
            # for nightly Zig (`.master`) take zls from the zigtools/zls
            # flake instead. See
            # https://github.com/mpriscella/dotfiles/blob/main/docs/zig.md.
            inputs.zig-overlay.packages.${system}.default
            pkgs.zls
          ];

          # Set any environment variables for your development environment.
          env = {};

          # Add any shell logic you want executed when the environment is
          # activated.
          shellHook = "";
        };
      }
    );

    # Default checks for this flake.
    checks = forEachSupportedSystem (
      {pkgs, ...}: {
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
