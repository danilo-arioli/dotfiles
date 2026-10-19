#!/usr/bin/env bash
# Symlink the dotfiles with GNU stow, backing up anything already in the way.
#
# Why the backup step exists: stow refuses to link over a *real* file. If
# ~/.zshrc exists as a regular file (as it does after a manual setup), `stow .`
# aborts with a conflict and the config silently never gets linked. We move the
# offender into a timestamped backup directory first, then let stow do its job.

BACKUP_ROOT="$HOME/.dotfiles-backup"

# Directories that only make sense on an Arch desktop running Hyprland.
GUI_ONLY_DIRS=(hypr waybar wofi backgrounds)

# Populates the global STOW_IGNORE_ARGS array with extra --ignore flags.
# (A global rather than stdout: macOS still ships bash 3.2, which has no
# mapfile, and an empty array under `set -u` is awkward to pass around.)
STOW_IGNORE_ARGS=()
stow_ignore_args() {
  STOW_IGNORE_ARGS=()
  if ! is_desktop_linux; then
    local re
    re="$(IFS='|'; echo "${GUI_ONLY_DIRS[*]}")"
    STOW_IGNORE_ARGS=(--ignore="^($re)\$")
  fi
}

# Ask stow what it would do and collect the paths (relative to $HOME) it
# refuses to overwrite. stow 2.3/2.4 word this two different ways:
#   * cannot stow X over existing target .zshrc since neither a link nor ...
#   * existing target is not owned by stow: .config/foo/bar
find_conflicts() {
  stow_ignore_args
  stow --simulate --verbose=1 --target="$HOME" \
       ${STOW_IGNORE_ARGS[@]+"${STOW_IGNORE_ARGS[@]}"} . 2>&1 >/dev/null \
    | sed -nE \
        -e 's/.*cannot stow .* over existing target ([^ ]+) since.*/\1/p' \
        -e 's/.*existing target is (not owned by stow|neither a link nor a directory): *(.+)$/\2/p' \
    | sort -u
}

# Move every conflicting real file into a timestamped backup directory.
# stow aborts at the first batch of conflicts it finds, so re-simulate after
# each round until it comes back clean (bounded, to never spin forever).
backup_conflicts() {
  local stamp backup_dir
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="$BACKUP_ROOT/$stamp"

  local found_any=0 round
  # shellcheck disable=SC2034  # $round is just the bound on the retry loop
  for round in 1 2 3 4 5; do
    local conflicts
    conflicts="$(find_conflicts)" || true
    [[ -z "$conflicts" ]] && break

    [[ "$found_any" == "0" ]] && info "Backing up conflicting files → $backup_dir"
    found_any=1

    local rel src
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      src="$HOME/$rel"
      [[ -e "$src" || -L "$src" ]] || continue
      if [[ "${DRY_RUN:-0}" == "1" ]]; then
        printf '%s  would back up:%s ~/%s\n' "$C_DIM" "$C_RESET" "$rel"
        continue
      fi
      mkdir -p "$backup_dir/$(dirname "$rel")"
      mv "$src" "$backup_dir/$rel"
      ok "$HOME/$rel → $backup_dir/$rel"
    done <<< "$conflicts"

    # In dry-run nothing was actually moved, so a second round would loop.
    [[ "${DRY_RUN:-0}" == "1" ]] && break
  done

  [[ "$found_any" == "0" ]] && ok "No conflicting files in \$HOME"
  return 0
}

# True when $1 is a directory stow already manages, i.e. it is either a symlink
# into the repo or contains at least one symlink into the repo. Such a directory
# is a legitimate stow result (stow cannot fold a tree whose README/LICENSE are
# ignored, so it creates a real dir full of symlinks) and must not be touched.
is_stow_managed() {
  local target="$1"
  [[ -L "$target" ]] && [[ "$(readlink -f "$target")" == "$DOTFILES_DIR"/* ]] && return 0
  local link
  while IFS= read -r link; do
    [[ "$(readlink -f "$link")" == "$DOTFILES_DIR"/* ]] && return 0
  done < <(find "$target" -maxdepth 2 -type l 2>/dev/null)
  return 1
}

# ~/.config/nvim and friends are often plain *copies* rather than symlinks.
# stow would descend into such a directory and link the files inside it, leaving
# a half-copied / half-linked mess where edits in the repo silently don't apply.
# Back the whole unmanaged copy up so stow can produce a clean result.
backup_copied_trees() {
  local stamp backup_dir
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="$BACKUP_ROOT/$stamp"

  local d name target
  for d in "$DOTFILES_DIR"/.config/*/; do
    name="$(basename "$d")"
    if ! is_desktop_linux && [[ " ${GUI_ONLY_DIRS[*]} " == *" $name "* ]]; then
      continue
    fi
    target="$HOME/.config/$name"
    [[ -e "$target" ]] || continue
    is_stow_managed "$target" && continue

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      printf '%s  would back up:%s ~/.config/%s (unmanaged copy, not a stow link)\n' \
        "$C_DIM" "$C_RESET" "$name"
      continue
    fi
    mkdir -p "$backup_dir/.config"
    mv "$target" "$backup_dir/.config/$name"
    ok "$HOME/.config/$name → $backup_dir/.config/$name"
  done
}

link_dotfiles() {
  have stow || die "GNU stow is not installed — package step must run first"

  info "Linking dotfiles from $DOTFILES_DIR"
  cd "$DOTFILES_DIR" || die "cannot cd to $DOTFILES_DIR"

  backup_copied_trees
  backup_conflicts

  stow_ignore_args

  if ! is_desktop_linux; then
    skip "Skipping Hyprland/waybar/wofi configs (not an Arch desktop)"
  fi

  run stow --restow --target="$HOME" ${STOW_IGNORE_ARGS[@]+"${STOW_IGNORE_ARGS[@]}"} . \
    || die "stow failed — see the conflicts above"

  ok "Dotfiles linked"
}
