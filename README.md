# Dotfiles

Neovim, zsh, tmux, Ghostty and Hyprland configuration, plus a bootstrap script
that sets up a full dev environment on macOS, Arch Linux and WSL2.

<img width="1669" alt="neovim-screen-1" src="https://github.com/user-attachments/assets/9bfc6eda-a899-49ec-95ce-dd2d0057beec" />
<img width="1669" alt="neovim-screen-2" src="https://github.com/user-attachments/assets/fd414d01-df13-4c16-8552-bd54803092d0" />

## Install

```bash
git clone https://github.com/danilo-arioli/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

On Windows, run it **inside WSL2** (Ubuntu or Debian). There is no
native-Windows path — the config is zsh/tmux based.

Always worth doing first:

```bash
./install.sh --dry-run    # prints every action, changes nothing
```

### Options

| Flag | Effect |
| --- | --- |
| `--dry-run`, `-n` | Print what would happen; change nothing |
| `-y`, `--yes` | Never prompt |
| `--only <steps>` | Run only these steps (comma-separated) |
| `--skip <steps>` | Run everything except these steps |
| `-h`, `--help` | Usage |

Steps, in order: `packages`, `node`, `link`, `tpm`, `shell`.

```bash
./install.sh --only link        # just re-link the dotfiles
./install.sh --skip packages    # everything but package installation
```

## What it installs

| | macOS | Arch | Debian / WSL2 |
| --- | --- | --- | --- |
| Package manager | Homebrew (installed if missing) | pacman | apt |
| Core | git, stow, zsh, neovim, tmux | same | same (neovim from the upstream tarball — apt's is too old) |
| CLI | ripgrep, fd, fzf, eza, zoxide, bat, jq, lazygit, yazi | same | apt where available, GitHub release binaries into `~/.local/bin` otherwise |
| PHP | php + composer (brew) | php + composer (pacman) | php-cli & extensions (apt) + Composer via the verified installer |
| Node | nvm → node LTS → pnpm (corepack) | same | same |
| Claude Code | `claude-code` cask | native installer → `~/.local/bin` | native installer → `~/.local/bin` |
| Terminal | Ghostty + JetBrainsMono Nerd Font (casks) | Ghostty + `ttf-jetbrains-mono-nerd` | font skipped under WSL2 — install it on the Windows host |
| Desktop | — | Hyprland, waybar, wofi, hyprlock, hypridle & friends | — |

The Hyprland/waybar/wofi configs are only linked on a **non-WSL Arch** machine.
Everywhere else they are skipped, so `~/.config` doesn't fill up with configs
for a compositor that isn't there.

## How linking works

`install.sh` uses [GNU Stow](https://www.gnu.org/software/stow/) to symlink this
repo into `$HOME`.

Stow refuses to link over a **real** file, and when it hits one it aborts the
whole operation. That is why a plain `stow .` could silently leave `~/.zshrc`
unlinked: the file already existed as a regular file, stow bailed, and the
config kept being read from the stale copy.

The `link` step handles this: before stowing it simulates the run, moves every
conflicting file to `~/.dotfiles-backup/<timestamp>/`, and repeats until stow
reports a clean run. Nothing is ever deleted. It also detects a `~/.config/<x>`
directory that is a plain *copy* rather than a stow symlink and backs that up
too, so you don't end up with a half-linked tree.

`.stow-local-ignore` keeps `install.sh`, `scripts/` and the README out of `$HOME`.

## Machine-specific config

Anything that differs per machine goes in `~/.zshrc.local`, which the tracked
`.zshrc` sources last and git ignores:

```bash
cp .zshrc.local.example ~/.zshrc.local
```

The tracked `.zshrc` is platform-aware on its own — it picks the right Homebrew
prefix, the right `PNPM_HOME` (`~/Library/pnpm` on macOS, `~/.local/share/pnpm`
on Linux), and guards every tool init with `command -v`, so a missing tool
degrades gracefully instead of erroring on shell startup.

Two things to keep in mind when editing `.zshrc`:

- The Powerlevel10k instant-prompt block must stay at the very top, and nothing
  above it may print anything. A stray `echo` there breaks the instant prompt.
- `brew shellenv` runs before any tool init, so `zoxide`, `eza` and friends are
  on `$PATH` by the time they are used.

## After installing

1. Open a new terminal (or `exec zsh`) — zinit fetches its plugins on first run.
2. Run `nvim` once; lazy.nvim and Mason install plugins, LSP servers and formatters.
3. Set your terminal font to **JetBrainsMono Nerd Font**.
