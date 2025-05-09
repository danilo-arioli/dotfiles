# Neovim and other configurations

<img width="1669" alt="neovim-screen-1" src="https://github.com/user-attachments/assets/9bfc6eda-a899-49ec-95ce-dd2d0057beec" />
<img width="1669" alt="neovim-screen-2" src="https://github.com/user-attachments/assets/fd414d01-df13-4c16-8552-bd54803092d0" />


## Prerequisites

*   [GNU Stow](https://www.gnu.org/software/stow/): For symlinking the dotfiles.
    *   On macOS (using Homebrew): `brew install stow`
    *   On Debian/Ubuntu: `sudo apt install stow`
    *   On Arch Linux: `sudo pacman -S stow`
*   Node and NPM, Ripgrep and a Nerd Font for the Neovim config

## Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/danilo-arioli/dotfiles.git ~/dotfiles
    ```


2.  **Navigate to the dotfiles directory:**

    ```bash
    cd ~/dotfiles
    ```

3.  **Use Stow to symlink the configurations:**

    To install all configurations:
    ```bash
    stow .
    ```
