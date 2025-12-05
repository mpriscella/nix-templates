# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of Nix flake templates for bootstrapping project dev environments.
Consumers run `nix flake init --template github:mpriscella/nix-templates#<template>`
and get a self-contained flake providing a `direnv`-activated dev shell. There is
no application code here — every file is a template or the flake that aggregates
them.

## Commands

```shell
nix flake check          # Runs all checks (alejandra format check + devshell build) across every supportedSystem
nix fmt                  # Format all .nix files (alejandra); the same check runs in `nix flake check`
alejandra .              # Format directly
nix develop              # Enter the root dev shell (empty by default)
```

Test a template end-to-end by initializing it into a scratch directory:

```shell
cd (mktemp -d); nix flake init --template /Users/mpriscella/workspace/mpriscella/nix-templates#<template>
```

Formatting is enforced: `alejandra --check` is a flake check, so unformatted
`.nix` files fail CI. Run `nix fmt` before finishing.

## Architecture

### Template registration

The root `flake.nix` exposes every template via its `templates` output as
`{ path = ./templates/<name>; description = "..."; }`. A template directory is
invisible until it's added there.

### Shared template skeleton

Every template flake follows the same structure — when adding or editing one,
match this exactly rather than inventing a new shape:

- `supportedSystems` = the four Linux/Darwin × x86_64/aarch64 tuples.
- `forEachSupportedSystem` helper wraps `nixpkgs.lib.genAttrs`, importing nixpkgs
  with `config.allowUnfree = true` per system.
- `formatter` = `pkgs.alejandra`.
- `devShells.default` = a `pkgs.mkShell` with `packages`, `env`, and `shellHook`.
- `checks` = `format` (runs `alejandra --check`) + `build-devshell` (builds the
  default shell).

The per-template customization lives entirely in the `devShells.default` block:

- **laravel** — pins the language runtime explicitly (`php84`, `nodejs_24`) so a
  nixpkgs bump never silently changes the version. Its `shellHook` scaffolds a
  fresh app via `laravel new` when no `artisan` exists.
- **zig** — adds the `zig-overlay` input and threads `system` through
  `forEachSupportedSystem` (the only template that does) to select a pinned
  compiler; `zls` comes from nixpkgs. See the README for version-matching rules.

### nixpkgs source is not uniform

Templates use one of two nixpkgs URLs: `github:NixOS/nixpkgs/nixpkgs-unstable`
(root, drupal) or `https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1`
(laravel, zig). Keep a template on whichever it already uses unless there's a
reason to change it.

### `.envrc`

Every template ships the same `.envrc` (`if has nix; then use flake; fi`) so
`direnv allow` activates the shell. `.direnv/` is gitignored.

## Adding a new template

1. Create `templates/<name>/` with a `flake.nix` (copy the skeleton from an
   existing template) and the shared `.envrc`.
2. Register it in the root `flake.nix` `templates` attribute with a `path` and
   `description`.
3. Add a row to the README's Templates table.
4. Run `nix fmt` and `nix flake check`.
