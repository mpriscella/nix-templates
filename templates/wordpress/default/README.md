# WordPress Development Environment


TODO: Is there a way to download the latest stable version of WordPress entirely
and run it using wp-env?


This Nix flake provides a local WordPress development environment using the
[`@wordpress/env`](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/#add-mu-plugins-and-other-mapped-directories)
npm package and Docker.

## Requirements

- Either [Docker](https://www.docker.com/products/docker-desktop/) __or__
  [OrbStack](https://orbstack.dev/)
- [Nix](https://nixos.org/) with flakes enabled
- [direnv](https://direnv.net/) (optional)

## Packages Bundled in Nix Shell

- NodeJS 24
- PHP 8.4
- Composer

## Quick Start

- Enter the dev shell:
  - With direnv: allow the directory once, then it auto-activates (`direnv
    allow`)
  - Without direnv: run `nix develop`
- Install dependencies: `npm install`
- Start WordPress: `wp-env start`
- Open: http://localhost:8888 (tests site on 8889)
- Username is `admin`, password is `password`

## Working on Plugins and Themes

- Add your plugin under `plugins/<your-plugin>/` and create a mount
- Add your theme under `themes/<your-theme>/` and create a mount

## Configuration

wp-env is configured via `.wp-env.json` to map local folders into `wp-content`:

```json
{
  "plugins": [],
  "themes": []
  "mappings": {
    "wp-content/themes": "./themes",
    "wp-content/plugins": "./plugins"
  }
}
```

You can find the schema [here](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/#wp-env-json)

- Add paths or Git URLs to `plugins`/`themes` arrays if you want wp-env to fetch
  additional sources

## Common Commands

- `wp-env start`: Build and start the containers
- `wp-env stop`: Stop containers (volumes remain)
- `wp-env destroy`: Remove containers and volumes
- `wp-env logs`: Show container logs
- `wp-env run cli wp <command>`: Run WP-CLI inside the WordPress container

## Troubleshooting

- Docker not running: Ensure the Docker daemon is started
- Port in use: Change ports via `.wp-env.json` options or stop the conflicting
  service
