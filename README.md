# Dotfiles

[![chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-00A0FF.svg)](https://www.chezmoi.io/)
![License](https://img.shields.io/badge/license-MIT-blue)

My personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Includes configurations for:

- 🐚 Fish Shell (with plugins/aliases)
- ✨ Starship prompt
- 🧪 Neovim (LazyVim-based config)
- 🖥️ Terminal: Alacritty & Kittyww
- 🧩 Development: Go, Python, Ruby, Rust
- 🧰 Tools: fzf, zoxide, direnv, asdf, docker
- 🪟 Window Management: Amethyst layouts
- 📦 Package Management: Homebrew (Brewfile)


## 🚀 Quick Start (New Mac)
```bash
# 1) Install Homebrew (if you don't have it)
#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2) Install chezmoi
brew install chezmoi

# 3) Pull & apply my dotfiles in one go
chezmoi init --apply https://github.com/<your-github-username>/dotfiles.git

# 4) Install Homebrew packages defined in the Brewfile
brew bundle --file "$HOME/Brewfile"

# 5) Sanity check
chezmoi doctor
```
