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
