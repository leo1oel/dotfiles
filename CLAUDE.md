# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository managed with **chezmoi**, a dotfile management tool that handles templating, secrets, and cross-platform configurations. The repository supports both **macOS** and **Ubuntu/Linux**.

## Repository Structure

### Chezmoi Architecture

Chezmoi uses a special naming convention for files and directories:

- `dot_` prefix → becomes `.` in the target system (e.g., `dot_gitconfig.tmpl` → `~/.gitconfig`)
- `private_` prefix → indicates files with restricted permissions (0600)
- `.tmpl` suffix → files are Go templates that get processed
- `executable_` prefix → files become executable scripts

**Key directories:**
- `.chezmoiscripts/` - Automation scripts that run during `chezmoi apply`
  - `run_once_before_*` - Runs once before applying dotfiles
  - `run_onchange_*` - Runs when the file's hash changes
- `dot_config/` - Maps to `~/.config/`
- `private_dot_local/` - Maps to `~/.local/`

### Configuration Locations

- **Fish shell**: `dot_config/private_fish/` - Main shell configuration
  - `config.fish` - Main config with Zellij auto-attach
  - `conf.d/*.fish` - Modular configurations loaded in order (00, 10, 20, etc.)
  - `functions/` - Custom Fish functions
- **Neovim**: `dot_config/nvim/` - LazyVim-based configuration
- **Git**: `dot_gitconfig.tmpl` - Template that includes user-specific settings
- **Brewfile**: `dot_config/Brewfile` - Homebrew packages for macOS
- **Ubuntu packages**: `dot_config/packages.ubuntu` - APT packages for Ubuntu/Linux
- **Nix**: `dot_config/nix/flake.nix` - Alternative package management via Home Manager

## Working with Dotfiles

### Testing Changes

**Never test directly on the live system.** Use chezmoi's built-in commands:

```bash
# Preview changes before applying
chezmoi diff

# Apply changes to home directory
chezmoi apply

# Apply with verbose output
chezmoi apply -v

# Dry-run to see what would change
chezmoi apply --dry-run

# Edit a managed file (automatically opens in editor)
chezmoi edit ~/.gitconfig

# Check repository health
chezmoi doctor
```

### Managing Templates

Files ending in `.tmpl` are processed as Go templates with access to:

- `.chezmoi.os` - Operating system (darwin, linux)
- `.username` - User's Git username (from `.chezmoi.toml.tmpl`)
- `.email` - User's Git email (from `.chezmoi.toml.tmpl`)
- `secret` function - Retrieves secrets via `get-secret.sh` script

**Example template usage:**
```
{{ if eq .chezmoi.os "darwin" }}
# macOS-specific config
{{ end }}

api_key = {{ secret "api-key/google" "default-value" }}
```

### Secret Management

Secrets are managed using `pass` (password-store):

- Secrets retrieved via `private_dot_local/bin/executable_get-secret.sh`
- Script wrapper around `pass` command
- Format: `get-secret.sh <secret-path> [default-value]`
- Secrets stored in `.chezmoi.toml.tmpl` are populated on first run

### Adding/Modifying Packages

**macOS (Homebrew):**

1. Edit `dot_config/Brewfile` directly
2. Test installation: `brew bundle --file ~/.config/Brewfile`
3. The `run_onchange_install-packages.sh.tmpl` script automatically detects Brewfile changes

**Ubuntu/Linux (APT):**

1. Edit `dot_config/packages.ubuntu` (one package name per line)
2. Comments start with `#`
3. The `run_onchange_install-packages.sh.tmpl` script automatically installs packages when the file changes
4. Special packages installed by `run_once_before_install-package-manager.sh.tmpl`:
   - **Via PPA**: helix, lazygit
   - **Via curl installer**: starship, uv, fnm
   - **Via custom repo**: eza
   - **Via GitHub releases**: git-delta, zellij
   - **Symlinked**: bat (from batcat), fd (from fdfind)

**Nix packages** (cross-platform):

1. Edit `dot_config/nix/flake.nix`
2. Update flake: `nix flake update`
3. Apply (auto-detects your platform):
   ```bash
   home-manager switch --flake ~/.config/nix#leonardo
   ```
   Or specify platform explicitly:
   - Linux x86_64: `home-manager switch --flake ~/.config/nix#leonardo@x86_64-linux`
   - Linux ARM64: `home-manager switch --flake ~/.config/nix#leonardo@aarch64-linux`
   - macOS Intel: `home-manager switch --flake ~/.config/nix#leonardo@x86_64-darwin`
   - macOS Apple Silicon: `home-manager switch --flake ~/.config/nix#leonardo@aarch64-darwin`

### Fish Shell Configuration

Fish configs in `conf.d/` are loaded in numerical order:
- `00_*` - Initialization
- `10_*` - Prompt (Starship)
- `20_*` - Language runtimes (Python, Rust, Go, Node.js)
- `30_*` - Tools (Docker, Git)
- `50_*` - CLI utilities (chezmoi, eza, zoxide)
- `70_*` - Development tools (asdf, direnv, fzf)
- `80_*` - Editors (Helix)
- `90_*` - Aliases and custom functions
- `95_*` - Local overrides and SSH

**Common aliases** (from `90_aliases.fish`):
- `vi`, `nano` → `nvim`
- `zz` → `zellij`
- `cz` → `chezmoi`

### GenAI Integration

Fish shell includes AI-powered command suggestions via `fish-ai`:
- Configuration: `dot_config/fish-ai.ini.tmpl`
- Providers: Google Gemini (default), local Ollama
- Keybindings: Ctrl+P, Ctrl+\

## Development Environments

This repository configures multiple development environments:

**Python:**
- `pyenv` for version management
- `uv` for fast package management
- Multiple LSPs: `pyright`, `python-lsp-server`, `pylyzer`

**Go:**
- Managed via package managers (Homebrew/APT)
- `golines` formatter included

**Node.js:**
- `fnm` (Fast Node Manager)
- Alternative: `nvm` function wrapper

**Note:** This configuration uses many modern CLI tools written in Rust (ripgrep, bat, eza, fd, starship, helix, zoxide, zellij) but does **not** include Rust development environment. These tools are installed as pre-compiled binaries via package managers.

**All environments** include LSPs and formatters configured for Helix and Neovim.

## Automation Scripts

### Installation Flow

1. `run_once_before_install-package-manager.sh.tmpl`:
   - **macOS**: Installs Homebrew and Fish shell
   - **Ubuntu/Linux**:
     - Installs Fish shell from PPA
     - Adds PPAs for Helix and LazyGit
     - Installs tools via curl: Starship, uv, fnm
     - Installs eza (from custom repo), git-delta, zellij, chezmoi
     - Creates symlinks for `bat` (batcat) and `fd` (fdfind)
   - Sets Fish as default shell on both platforms

2. `run_onchange_install-packages.sh.tmpl`:
   - **macOS**: Runs when Brewfile changes (hash-based detection), executes `brew bundle`
   - **Ubuntu/Linux**: Runs when packages.ubuntu changes, executes `apt install` for listed packages

3. `.install-password-manager.sh`:
   - Triggered by `hooks.read-source-state.pre` in `.chezmoi.toml.tmpl`
   - Installs `get-secret.sh` to `~/.local/bin/`

## Platform-Specific Configurations

### macOS Only

Files/configs ignored on non-macOS systems (via `.chezmoiignore`):
- `.config/Brewfile` - Homebrew package list

### Ubuntu/Linux Only

Files/configs ignored on non-Linux systems (via `.chezmoiignore`):
- `.config/packages.ubuntu` - APT package list

### Cross-Platform

Most configurations work on both platforms:
- Fish shell configurations
- Git configuration (with OS-specific sections)
- Neovim/Helix editor configs
- All dotfiles in `dot_config/`

## Common Tasks

**Add a new dotfile to management:**
```bash
chezmoi add ~/.config/new-app/config.toml
```

**Update from repository:**
```bash
chezmoi update
```

**Re-apply all dotfiles:**
```bash
chezmoi apply --force
```

**Add a new package:**

*macOS:*
1. Add to `dot_config/Brewfile`
2. Run `chezmoi apply` (triggers automatic installation via hash detection)

*Ubuntu/Linux:*
1. Add to `dot_config/packages.ubuntu`
2. Run `chezmoi apply` (triggers automatic installation via hash detection)

**Add a new Fish function:**
```bash
chezmoi edit ~/.config/fish/functions/my-function.fish
```

## Architecture Notes

### Zellij Auto-Attach

When using Kitty terminal with `KITTY_SESSION` environment variable set:
- Fish automatically attaches/creates a Zellij session
- Session name matches `KITTY_SESSION` value
- Provides seamless terminal multiplexing

### Git Configuration Strategy

- Base config in `dot_gitconfig.tmpl` with user details from chezmoi data
- Local overrides via `~/.gitconfig.local` (included at end of base config)
- Delta pager for better diff viewing
- Meld as difftool on macOS

## Important Files

- `.chezmoi.toml.tmpl` - Chezmoi configuration with user prompts and hooks
- `.chezmoiignore` - Platform-specific file exclusions
- `dot_config/Brewfile` - macOS package list (Homebrew)
- `dot_config/packages.ubuntu` - Ubuntu/Linux package list (APT)
- `private_dot_local/bin/executable_get-secret.sh` - Secret retrieval wrapper
- `.chezmoiscripts/` - Automated installation scripts for both platforms
