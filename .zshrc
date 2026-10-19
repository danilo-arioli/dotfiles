# ─────────────────────────────────────────────────────────────────────────────
# Powerlevel10k instant prompt — must stay at the very top.
# Nothing above this line may produce output (no echo!) or the prompt breaks.
# ─────────────────────────────────────────────────────────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Platform detection
# ─────────────────────────────────────────────────────────────────────────────
case "$OSTYPE" in
  darwin*) DOTFILES_OS="macos" ;;
  linux*)  DOTFILES_OS="linux" ;;
  *)       DOTFILES_OS="unknown" ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# Homebrew — initialised FIRST so everything installed by brew is on $PATH
# for the rest of this file (zoxide, eza, fzf, ...).
# ─────────────────────────────────────────────────────────────────────────────
for brew_prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
  if [[ -x "$brew_prefix/bin/brew" ]]; then
    eval "$("$brew_prefix/bin/brew" shellenv)"
    break
  fi
done
unset brew_prefix

# ─────────────────────────────────────────────────────────────────────────────
# PATH
# ─────────────────────────────────────────────────────────────────────────────
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.config/composer/vendor/bin"
  "$HOME/.composer/vendor/bin"
  $path
)

# pnpm — location differs per platform
if [[ "$DOTFILES_OS" == "macos" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi
path=("$PNPM_HOME" $path)

# Homebrew python (only if that exact version is installed)
for py in /opt/homebrew/opt/python@3.14 /usr/local/opt/python@3.14; do
  [[ -d "$py/libexec/bin" ]] && path=("$py/libexec/bin" $path) && break
done
unset py

# Drop non-existent and duplicate entries
path=($^path(N))
typeset -U path PATH
export PATH

export EDITOR="nvim"
export VISUAL="$EDITOR"

# ─────────────────────────────────────────────────────────────────────────────
# Zinit + plugins
# ─────────────────────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# ─────────────────────────────────────────────────────────────────────────────
# Version managers
# ─────────────────────────────────────────────────────────────────────────────
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# ─────────────────────────────────────────────────────────────────────────────
# Completions
# ─────────────────────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ─────────────────────────────────────────────────────────────────────────────
# Tool init — each guarded so a missing tool never breaks the shell
# ─────────────────────────────────────────────────────────────────────────────
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ─────────────────────────────────────────────────────────────────────────────
# Keybindings
# ─────────────────────────────────────────────────────────────────────────────
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# ─────────────────────────────────────────────────────────────────────────────
# History
# ─────────────────────────────────────────────────────────────────────────────
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ─────────────────────────────────────────────────────────────────────────────
# Aliases & functions
# ─────────────────────────────────────────────────────────────────────────────
command -v eza >/dev/null && alias ls='eza'
command -v nvim >/dev/null && alias vim='nvim'
command -v zoxide >/dev/null && alias cd='z'
alias c='clear'

# yazi: cd into the directory yazi exits in
function y() {
  local tmp cwd
  tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ─────────────────────────────────────────────────────────────────────────────
# Machine-local overrides — NOT tracked in git.
# Put anything host-specific here (work proxies, app aliases, secrets).
# See .zshrc.local.example in the dotfiles repo.
# ─────────────────────────────────────────────────────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
