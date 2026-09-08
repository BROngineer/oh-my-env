#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MISE_REPO="jdx/mise"
MISE_VERSION="${MISE_VERSION:-latest}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux) echo linux ;;
    *) die "unsupported OS: $(uname -s)" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo arm64 ;;
    x86_64|amd64) echo x64 ;;
    armv7l) echo armv7 ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
}

# resolves "latest" to a concrete tag via the redirect GitHub issues for /releases/latest,
# avoiding a dependency on jq/the API for the common case
resolve_version() {
  local version="$1"
  if [ "$version" != "latest" ]; then
    printf '%s' "${version#v}"
    return
  fi
  local location
  location="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${MISE_REPO}/releases/latest")"
  [ -n "$location" ] || die "could not resolve latest mise version"
  printf '%s' "${location##*/v}"
}

install_mise() {
  local os arch version asset url tmp_dir

  os="$(detect_os)"
  arch="$(detect_arch)"
  version="$(resolve_version "$MISE_VERSION")"
  asset="mise-v${version}-${os}-${arch}"
  url="https://github.com/${MISE_REPO}/releases/download/v${version}/${asset}"

  if command -v mise >/dev/null 2>&1 && [ "$(mise --version | awk '{print $1}')" = "${version}" ]; then
    log "mise ${version} already installed, skipping"
    return
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  log "downloading ${asset} (mise ${version})"
  curl -fsSL -o "${tmp_dir}/mise" "$url"

  log "verifying checksum"
  local shasums_url="https://github.com/${MISE_REPO}/releases/download/v${version}/SHASUMS256.txt"
  curl -fsSL -o "${tmp_dir}/SHASUMS256.txt" "$shasums_url"
  local expected actual
  expected="$(grep "${asset}\$" "${tmp_dir}/SHASUMS256.txt" | awk '{print $1}')"
  [ -n "$expected" ] || die "no checksum entry found for ${asset}"
  actual="$(sha256 "${tmp_dir}/mise")"
  [ "$expected" = "$actual" ] || die "checksum verification failed for ${asset}"

  mkdir -p "$INSTALL_DIR"
  chmod +x "${tmp_dir}/mise"
  mv "${tmp_dir}/mise" "${INSTALL_DIR}/mise"
  log "installed mise ${version} to ${INSTALL_DIR}/mise"

  case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) ;;
    *) log "note: ${INSTALL_DIR} is not on PATH, add it to your shell profile" ;;
  esac

  # a running shell may have `mise` activated as a function baked with the old
  # binary path (e.g. a prior brew install); this process can't refresh that
  # shell's own state, so just tell the user how to
  if [ -n "${MISE_SHELL:-}" ]; then
    log "note: your current shell already has mise activated; run 'exec \$SHELL -l' or open a new terminal to pick up this binary"
  fi
}

configure_zsh_activation() {
  local zshrc="$HOME/.zshrc"
  local activate_line='eval "$(mise activate zsh)"'

  touch "$zshrc"
  if grep -qF "$activate_line" "$zshrc"; then
    log "mise activation already present in ${zshrc}"
    return
  fi

  printf '\n%s\n' "$activate_line" >> "$zshrc"
  log "added mise activation to ${zshrc}"
}

configure_oh_my_env_tool() {
  local src="${SCRIPT_DIR}/mise/bootstrap.toml"
  local dest_dir="$HOME/.config/mise"
  local dest="${dest_dir}/config.toml"

  if [ -e "$dest" ]; then
    log "${dest} already exists, skipping"
    return
  fi

  mkdir -p "$dest_dir"
  cp "$src" "$dest"
  log "installed oh-my-env mise tool config to ${dest}"
}

install_mise
configure_zsh_activation
configure_oh_my_env_tool
