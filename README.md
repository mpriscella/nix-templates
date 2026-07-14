# Nix Templates

Flake templates for project development environments. Start a new project
with:

```shell
nix flake init --template github:mpriscella/nix-templates#<template>
direnv allow
```

## Templates

| Template  | Description                                                         |
| --------- | ------------------------------------------------------------------- |
| `default` | Minimal multi-system flake with dev shell and format checks         |
| `laravel` | Laravel app/package dev shell; installer included for scaffolding   |
| `zig`     | Zig dev shell with the toolchain pinned via zig-overlay             |

### `laravel`

The dev shell pins PHP (edit `php84` in `flake.nix` to match the project)
and ships Composer, the Laravel installer, and Node. It does not touch an
existing app. If the directory has no `artisan`, the shell prints a hint to
run `laravel new .` — scaffolding stays opt-in.

### `zig`

The compiler comes from [zig-overlay](https://github.com/mitchellh/zig-overlay)
so any official release or nightly can be pinned; zls comes from nixpkgs,
which matches tagged releases. For nightly Zig, take zls from the
[zigtools/zls](https://github.com/zigtools/zls) flake instead. See
[dotfiles docs/zig.md](https://github.com/mpriscella/dotfiles/blob/main/docs/zig.md)
for the full version-matching rules.
