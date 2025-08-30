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

### 1) Install Homebrew (if you don't have it)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2) Prepare custom environment data for Chezmoi
```bash
mkdir -p "$HOME/.config/chezmoi"
wget -O "$HOME/.config/chezmoi/chezmoi.toml" https://raw.githubusercontent.com/joelee/chezmoi_dotfiles/eb7e0811d2ee6c66098a97072a35bfcc07a9500d/chezmoi_example.toml
# Edit the chezmoi.toml file with your favourite editor.
vi "$HOME/.config/chezmoi/chezmoi.toml"
```

### 3) Install chezmoi
```bash
brew install chezmoi
```

### 4) Pull & apply my dotfiles in one go
```bash
chezmoi init --apply https://github.com/joelee/chezmoi_dotfiles.git
```

### 5) Install Homebrew packages defined in the Brewfile
```bash
brew bundle --file "$HOME/.config/Brewfile"
```

### 6) Sanity check
```bash
chezmoi doctor
```

### 7) Enable Fish Shell
```bash
sudo -sh -c "echo /opt/homebrew/bin/fish >> /etc/shells"
```
Restart your Terminal

### 8) Activate Fish Shell
```bash
chsh -s /opt/homebrew/bin/fish
```
Restart your terminal again
