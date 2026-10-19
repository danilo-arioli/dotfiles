#!/usr/bin/env bash
# Shared helpers: logging, OS detection, small install utilities.

# ── Logging ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'
else
  C_RESET=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_DIM=''
fi

info()  { printf '%s==>%s %s\n' "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf '%s  ✓%s %s\n' "$C_GREEN"  "$C_RESET" "$*"; }
warn()  { printf '%s  !%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()   { printf '%s  ✗%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; }
skip()  { printf '%s  ·%s %s\n' "$C_DIM"    "$C_RESET" "$*"; }
die()   { err "$*"; exit 1; }

have()  { command -v "$1" >/dev/null 2>&1; }

# Run a command, or just print it when DRY_RUN=1.
run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '%s  would run:%s %s\n' "$C_DIM" "$C_RESET" "$*"
    return 0
  fi
  "$@"
}

confirm() {
  [[ "${ASSUME_YES:-0}" == "1" ]] && return 0
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ── OS detection ─────────────────────────────────────────────────────────────
# Sets: OS_FAMILY (macos|arch|debian), IS_WSL (0|1), ARCH (x86_64|aarch64)
# shellcheck disable=SC2034  # these are consumed by packages.sh / stow.sh
detect_os() {
  ARCH="$(uname -m)"
  IS_WSL=0
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
    IS_WSL=1
  fi

  case "$(uname -s)" in
    Darwin)
      OS_FAMILY="macos"
      ;;
    Linux)
      local id id_like
      if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        id="$(. /etc/os-release && echo "${ID:-}")"
        id_like="$(. /etc/os-release && echo "${ID_LIKE:-}")"
      fi
      case "$id $id_like" in
        *arch*|*manjaro*|*endeavouros*) OS_FAMILY="arch" ;;
        *debian*|*ubuntu*)              OS_FAMILY="debian" ;;
        *) die "Unsupported Linux distro: '${id:-unknown}'. Supported: Arch, Debian/Ubuntu." ;;
      esac
      ;;
    *)
      die "Unsupported OS: $(uname -s). On Windows, run this inside WSL2."
      ;;
  esac
}

# True when we should install desktop/GUI configs and packages.
# Hyprland/waybar/wofi/ghostty only make sense on a real Arch desktop.
is_desktop_linux() { [[ "$OS_FAMILY" == "arch" && "$IS_WSL" == "0" ]]; }

# ── GitHub release binaries (used on Debian/WSL where apt is too old) ────────
# usage: gh_release_install <repo> <asset-regex> <binary-name>
# Downloads the latest release asset matching the regex, extracts it, and puts
# <binary-name> into ~/.local/bin.
gh_release_install() {
  local repo="$1" pattern="$2" binary="$3"
  local dest="$HOME/.local/bin"

  if have "$binary"; then
    skip "$binary already installed ($(command -v "$binary"))"
    return 0
  fi

  info "Installing $binary from github.com/$repo"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '%s  would download:%s %s asset matching %s\n' "$C_DIM" "$C_RESET" "$repo" "$pattern"
    return 0
  fi

  mkdir -p "$dest"
  local url
  url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
    | grep -oE '"browser_download_url": *"[^"]+"' \
    | cut -d'"' -f4 \
    | grep -E "$pattern" \
    | head -n1)" || true

  if [[ -z "$url" ]]; then
    warn "No release asset matching '$pattern' for $repo — skipping $binary"
    return 1
  fi

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  curl -fsSL "$url" -o "$tmp/asset" || { warn "Download failed: $url"; return 1; }

  case "$url" in
    *.tar.gz|*.tgz) tar -xzf "$tmp/asset" -C "$tmp" ;;
    *.tar.xz)       tar -xJf "$tmp/asset" -C "$tmp" ;;
    *.zip)          unzip -qo "$tmp/asset" -d "$tmp" ;;
    *)              mv "$tmp/asset" "$tmp/$binary"; chmod +x "$tmp/$binary" ;;
  esac

  local found
  found="$(find "$tmp" -type f -name "$binary" -perm -u+x | head -n1)"
  [[ -z "$found" ]] && found="$(find "$tmp" -type f -name "$binary" | head -n1)"
  if [[ -z "$found" ]]; then
    warn "Could not find '$binary' inside the $repo archive — skipping"
    return 1
  fi

  install -m 0755 "$found" "$dest/$binary"
  ok "$binary → $dest/$binary"
}
