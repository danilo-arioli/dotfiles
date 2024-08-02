# How to use



## Install neovim using the appimage version
```
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
sudo mv nvim.appimage /usr/local/bin/nvim
```

## Install packages for the neovim configuration to install correctly
```
# Update package list and install necessary packages
sudo apt update && \
sudo apt install -y ripgrep xclip build-essential lua5.3

# Install LazyGit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# Install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
source ~/.bashrc

# Install the latest stable version of Node.js using nvm
nvm install --lts

```

## Install zoxide, eza and fzf
```
# Install Rust and Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh && \
source $HOME/.cargo/env && \

# Install zoxide, eza, and fzf
cargo install zoxide eza fzf
```

## Install zsh and set it as your default shell
```
sudo apt install zsh && chsh -s /bin/zsh
```
> **Note:**  You may need to close and reopen the terminal



# Install stow and clone your dotfiles repository
```
sudo apt update && \
sudo apt install -y stow
git clone <repository-url> ~/dotfiles
cd ~/dotfiles

# Use stow to symlink the files
stow .

# Reload your shell configuration
source ~/.zshrc

# Launch Neovim to verify the setup
nvim
```
