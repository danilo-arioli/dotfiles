#!/usr/bin/env bash
#
# Bootstrap a dev environment from this dotfiles repo.
#
#   macOS        → Homebrew
#   Arch Linux   → pacman (+ Hyprland desktop configs on a real desktop)
#   Debian/Ubuntu → apt, plus upstream release binaries where apt lags
#   Windows      → run this inside WSL2 (it is detected as Debian/Ubuntu)
#
# Usage:
#   ./install.sh                 # everything
#   ./install.sh --dry-run       # show what would happen, change nothing
#   ./install.sh --only link     # just (re)link the dotfiles
#   ./install.sh --skip packages # everything except package installation
#   ./install.sh -y              # don't prompt
#
# Steps: packages, node, link, tpm, shell

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# shellcheck source=scripts/lib.sh
source "$DOTFILES_DIR/scripts/lib.sh"
# shellcheck source=scripts/packages.sh
source "$DOTFILES_DIR/scripts/packages.sh"
# shellcheck source=scripts/stow.sh
source "$DOTFILES_DIR/scripts/stow.sh"

ALL_STEPS=(packages node link tpm shell)
STEPS=("${ALL_STEPS[@]}")
DRY_RUN=0
ASSUME_YES=0

# Print the leading comment block (everything after the shebang up to the first
# non-comment line) as the help text.
usage() {
  awk 'NR==1 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1; shift ;;
    -y|--yes)     ASSUME_YES=1; shift ;;
    --only)
      [[ -n "${2:-}" ]] || die "--only needs a step name"
      IFS=',' read -r -a STEPS <<< "$2"; shift 2 ;;
    --skip)
      [[ -n "${2:-}" ]] || die "--skip needs a step name"
      IFS=',' read -r -a to_skip <<< "$2"
      local_steps=()
      for s in "${STEPS[@]}"; do
        [[ " ${to_skip[*]} " == *" $s "* ]] || local_steps+=("$s")
      done
      STEPS=("${local_steps[@]}"); shift 2 ;;
    -h|--help)    usage 0 ;;
    *)            err "Unknown option: $1"; usage 1 ;;
  esac
done
export DRY_RUN ASSUME_YES

for s in "${STEPS[@]}"; do
  [[ " ${ALL_STEPS[*]} " == *" $s "* ]] || die "Unknown step '$s' (valid: ${ALL_STEPS[*]})"
done

has_step() { [[ " ${STEPS[*]} " == *" $1 "* ]]; }

# ─────────────────────────────────────────────────────────────────────────────

detect_os

printf '\n'
info "dotfiles  : $DOTFILES_DIR"
info "platform  : $OS_FAMILY ($ARCH)$([[ "$IS_WSL" == "1" ]] && echo ' under WSL2')"
info "steps     : ${STEPS[*]}"
[[ "$DRY_RUN" == "1" ]] && warn "dry run — nothing will be changed"
printf '\n'

if [[ "$OS_FAMILY" != "macos" ]] && ! have sudo; then
  die "sudo is required but not installed"
fi

if has_step packages; then
  info "── Packages ─────────────────────────────────────────"
  case "$OS_FAMILY" in
    macos)  install_macos  ;;
    arch)   install_arch   ;;
    debian) install_debian ;;
  esac
  printf '\n'
fi

if has_step node; then
  info "── Node toolchain ───────────────────────────────────"
  install_node || warn "node setup incomplete"
  printf '\n'
fi

if has_step link; then
  info "── Dotfile symlinks ─────────────────────────────────"
  link_dotfiles
  printf '\n'
fi

if has_step tpm; then
  info "── tmux plugins ─────────────────────────────────────"
  install_tpm
  printf '\n'
fi

if has_step shell; then
  info "── Login shell ──────────────────────────────────────"
  set_default_shell || true
  printf '\n'
fi

info "── Done ─────────────────────────────────────────────"
cat <<EOF

  Next steps:
    1. Open a new terminal (or: exec zsh) — zinit will fetch its plugins.
    2. Run 'nvim' once; lazy.nvim and Mason will install plugins and LSP servers.
    3. Machine-specific config goes in ~/.zshrc.local
       (start from $DOTFILES_DIR/.zshrc.local.example — it is gitignored).
    4. Anything that was in the way was moved to ~/.dotfiles-backup/<timestamp>/

EOF
