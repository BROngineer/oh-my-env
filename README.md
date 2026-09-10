# oh-my-env
Portable env setup

## Usage

```sh
./install.sh
```

Installs [mise](https://mise.jdx.dev) to `~/.local/bin/mise`, picking the
release asset for your OS/arch and verifying it against the published
checksums.

### Options (env vars)

| Var            | Default             | Description                                   |
|----------------|---------------------|-----------------------------------------------|
| `MISE_VERSION` | `latest`            | mise version to install, e.g. `2026.9.3`      |
| `INSTALL_DIR`  | `$HOME/.local/bin`  | where the `mise` binary is placed             |

```sh
MISE_VERSION=2026.9.3 INSTALL_DIR="$HOME/bin" ./install.sh
```

Re-running the script is a no-op if the requested version is already
installed and on `PATH`.

Make sure `INSTALL_DIR` is on your `PATH`; the script warns if it isn't.

The script also:
- adds `eval "$(mise activate zsh)"` to `~/.zshrc` (skipped if already present)
- copies [`mise/bootstrap.toml`](mise/bootstrap.toml) to `~/.config/mise/config.toml`,
  **only if that file doesn't already exist** — a one-time seed, never
  overwritten by a re-run, so any changes made to `config.toml` afterwards
  (manual edits, or ones delivered via `mise up`, see below) are safe from
  the installer

`bootstrap.toml` declares `oh-my-env` itself as a `github:` tool with a
`postinstall` hook, so `mise up` fetches this repo's release assets and
drops any `configs/*.toml` and `configs/conf.d/*.toml` they contain into 
`~/.config/mise/` — letting the rest of the global config (settings, 
other tools, etc.) be delivered and updated through mise itself, rather 
than through this installer.
