#!/usr/bin/env bash
# Per-OS package installation.

# ─────────────────────────────────────────────────────────────────────────────
# macOS
# ─────────────────────────────────────────────────────────────────────────────
install_macos() {
  if ! have brew; then
    info "Installing Homebrew"
    run /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for p in /opt/homebrew /usr/local; do
      [[ -x "$p/bin/brew" ]] && eval "$("$p/bin/brew" shellenv)" && break
    done
  else
    ok "Homebrew present"
  fi

  info "Installing formulae"
  run brew install \
    git stow zsh neovim tmux \
    ripgrep fd fzf eza zoxide bat jq \
    lazygit yazi \
    php composer

  info "Installing casks"
  # Casks are allowed to fail individually (already installed by hand, etc.)
  for cask in ghostty font-jetbrains-mono-nerd-font; do
    if brew list --cask "$cask" >/dev/null 2>&1; then
      skip "cask $cask already installed"
    else
      run brew install --cask "$cask" || warn "cask $cask failed — install manually"
    fi
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# Arch Linux
# ─────────────────────────────────────────────────────────────────────────────
install_arch() {
  info "Installing pacman packages"
  local pkgs=(
    base-devel git stow zsh neovim tmux unzip curl
    ripgrep fd fzf eza zoxide bat jq
    lazygit yazi
    php composer
  )

  if is_desktop_linux; then
    pkgs+=(
      ghostty ttf-jetbrains-mono-nerd
      hyprland hyprpaper hyprlock hypridle waybar wofi
      xdg-desktop-portal-hyprland polkit-kde-agent qt5-wayland qt6-wayland
      grim slurp wl-clipboard
    )
  else
    skip "WSL/headless Arch — skipping Hyprland desktop packages"
  fi

  run sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Debian / Ubuntu (this is the WSL2 path)
# ─────────────────────────────────────────────────────────────────────────────
install_debian() {
  info "Updating apt and installing base packages"
  run sudo apt-get update
  run sudo apt-get install -y \
    build-essential git stow zsh tmux curl wget unzip file \
    ripgrep fd-find fzf bat jq \
    php-cli php-mbstring php-xml php-curl php-zip

  # Debian names these differently; provide the expected commands.
  mkdir -p "$HOME/.local/bin"
  [[ -x /usr/bin/fdfind  && ! -e "$HOME/.local/bin/fd"  ]] && ln -s /usr/bin/fdfind  "$HOME/.local/bin/fd"
  [[ -x /usr/bin/batcat  && ! -e "$HOME/.local/bin/bat" ]] && ln -s /usr/bin/batcat  "$HOME/.local/bin/bat"

  # apt's neovim is far too old for this config (needs >= 0.10) — use upstream.
  install_neovim_linux_tarball

  # Not packaged (or too old) on Debian/Ubuntu — pull upstream release binaries.
  # lazygit names its assets x86_64 / arm64 rather than using `uname -m`.
  local lazygit_arch
  case "$ARCH" in
    x86_64)  lazygit_arch="x86_64" ;;
    aarch64) lazygit_arch="arm64"  ;;
    *)       lazygit_arch="$ARCH"  ;;
  esac

  gh_release_install ajeetdsouza/zoxide    "zoxide-.*-${ARCH}-unknown-linux-musl\.tar\.gz"   zoxide  || true
  gh_release_install eza-community/eza     "eza_${ARCH}-unknown-linux-gnu\.tar\.gz"          eza     || true
  gh_release_install jesseduffield/lazygit "lazygit_.*_[Ll]inux_${lazygit_arch}\.tar\.gz"    lazygit || true
  gh_release_install sxyazi/yazi           "yazi-${ARCH}-unknown-linux-gnu\.zip"             yazi    || true

  install_composer_linux

  if [[ "$IS_WSL" == "1" ]]; then
    skip "WSL2 — install the JetBrainsMono Nerd Font on the Windows host instead"
    skip "      https://github.com/ryanoasis/nerd-fonts/releases (JetBrainsMono.zip)"
  else
    info "Installing JetBrainsMono Nerd Font"
    install_nerd_font_linux
  fi
}

install_neovim_linux_tarball() {
  # This config needs neovim >= 0.10. Compare numerically — a string compare
  # would rank "0.10" below "0.9".
  if have nvim; then
    local ver major minor
    ver="$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
    major="${ver%%.*}"; minor="${ver##*.}"
    if (( major > 0 || minor >= 10 )); then
      skip "neovim $ver already installed"
      return 0
    fi
    info "neovim $ver is too old (need >= 0.10) — replacing it"
  fi

  local nvim_arch
  case "$ARCH" in
    x86_64)  nvim_arch="linux-x86_64" ;;
    aarch64) nvim_arch="linux-arm64" ;;
    *) warn "No neovim tarball for $ARCH — install it yourself"; return 1 ;;
  esac

  info "Installing neovim (upstream tarball)"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '%s  would install:%s neovim %s to /opt/nvim\n' "$C_DIM" "$C_RESET" "$nvim_arch"
    return 0
  fi

  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-${nvim_arch}.tar.gz" \
    -o "$tmp/nvim.tar.gz" || { warn "neovim download failed"; rm -rf "$tmp"; return 1; }
  sudo rm -rf /opt/nvim
  sudo mkdir -p /opt/nvim
  sudo tar -xzf "$tmp/nvim.tar.gz" -C /opt/nvim --strip-components=1
  mkdir -p "$HOME/.local/bin"
  ln -sf /opt/nvim/bin/nvim "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
  ok "neovim → /opt/nvim (linked into ~/.local/bin)"
}

install_composer_linux() {
  if have composer; then
    skip "composer already installed"
    return 0
  fi
  info "Installing Composer"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '%s  would install:%s composer to /usr/local/bin\n' "$C_DIM" "$C_RESET"
    return 0
  fi
  local tmp; tmp="$(mktemp -d)"
  local expected actual
  expected="$(curl -fsSL https://composer.github.io/installer.sig)"
  curl -fsSL https://getcomposer.org/installer -o "$tmp/composer-setup.php"
  actual="$(php -r "echo hash_file('sha384', '$tmp/composer-setup.php');")"
  if [[ "$expected" != "$actual" ]]; then
    err "Composer installer checksum mismatch — aborting Composer install"
    rm -rf "$tmp"
    return 1
  fi
  php "$tmp/composer-setup.php" --install-dir="$tmp" --filename=composer
  sudo install -m 0755 "$tmp/composer" /usr/local/bin/composer
  rm -rf "$tmp"
  ok "composer → /usr/local/bin/composer"
}

install_nerd_font_linux() {
  local dir="$HOME/.local/share/fonts"
  if compgen -G "$dir/JetBrainsMono*" >/dev/null 2>&1; then
    skip "JetBrainsMono Nerd Font already installed"
    return 0
  fi
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '%s  would install:%s JetBrainsMono Nerd Font to %s\n' "$C_DIM" "$C_RESET" "$dir"
    return 0
  fi
  mkdir -p "$dir"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
    -o "$tmp/font.zip" && unzip -qo "$tmp/font.zip" -d "$dir" \
    && { have fc-cache && fc-cache -f "$dir" >/dev/null; ok "JetBrainsMono Nerd Font installed"; } \
    || warn "Nerd Font install failed — install it manually"
  rm -rf "$tmp"
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-platform: node toolchain via nvm
# ─────────────────────────────────────────────────────────────────────────────
install_node() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    ok "nvm present"
  else
    info "Installing nvm"
    run bash -c \
      "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash"
  fi

  [[ "${DRY_RUN:-0}" == "1" ]] && { skip "would install node LTS + pnpm via nvm"; return 0; }

  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" || { warn "nvm not loadable — skipping node"; return 1; }

  if nvm ls --no-colors 2>/dev/null | grep -q 'lts/\*'; then
    skip "node LTS already installed"
  else
    info "Installing node LTS"
    nvm install --lts
  fi
  nvm alias default 'lts/*' >/dev/null 2>&1 || true
  nvm use default >/dev/null 2>&1 || true

  if have corepack; then
    info "Enabling pnpm via corepack"
    corepack enable pnpm >/dev/null 2>&1 || npm install -g pnpm
  elif ! have pnpm; then
    info "Installing pnpm"
    npm install -g pnpm
  else
    skip "pnpm present"
  fi

  ok "node $(node --version 2>/dev/null), pnpm $(pnpm --version 2>/dev/null || echo 'n/a')"
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-platform: tmux plugin manager
# ─────────────────────────────────────────────────────────────────────────────
install_tpm() {
  local tpm="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm" ]]; then
    skip "tpm already cloned"
  else
    info "Cloning tmux plugin manager"
    run git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
  fi
  [[ "${DRY_RUN:-0}" == "1" ]] && return 0
  # Installs the plugins listed in .tmux.conf without needing a running server.
  [[ -x "$tpm/bin/install_plugins" ]] && "$tpm/bin/install_plugins" >/dev/null 2>&1 \
    && ok "tmux plugins installed" || warn "run prefix+I inside tmux to install plugins"
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-platform: make zsh the login shell
# ─────────────────────────────────────────────────────────────────────────────
set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)" || { warn "zsh not found — skipping shell change"; return 1; }

  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    ok "zsh is already the login shell"
    return 0
  fi

  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    info "Registering $zsh_path in /etc/shells"
    run sudo sh -c "echo '$zsh_path' >> /etc/shells"
  fi

  info "Setting zsh as the login shell (may prompt for your password)"
  run chsh -s "$zsh_path" || warn "chsh failed — run: chsh -s $zsh_path"
}
