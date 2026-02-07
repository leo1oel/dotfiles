# Repository Guidelines

## Project Structure & Module Organization
This repository manages personal dotfiles with `chezmoi` for macOS and Ubuntu.

- Root templates: `dot_*` and `private_dot_*` map to files under `$HOME`.
- App config: `dot_config/` (Fish, Neovim, Nix, Starship, package manifests).
- Automation scripts: `.chezmoiscripts/` (`run_once_*` and `run_onchange_*` lifecycle hooks).
- Helper binaries: `bin/` and `private_dot_local/bin/`.

Keep changes in the source tree here, then apply with `chezmoi` instead of editing generated files in `$HOME`.

## Build, Test, and Development Commands
Primary workflow is apply/validate rather than compile.

- `chezmoi diff` previews pending changes.
- `chezmoi apply` applies templates and runs change hooks.
- `chezmoi edit ~/.config/fish/config.fish` edits a managed file safely.
- `chezmoi update` pulls latest repo changes and applies them.
- `brew bundle --file ~/.config/Brewfile` refreshes macOS packages (also run by hooks).

Run commands from the managed machine where `chezmoi` is installed.

## Coding Style & Naming Conventions
Use `.editorconfig` defaults:

- UTF-8, LF, final newline, trimmed trailing whitespace.
- 2-space indentation for most files (`.sh`, `.fish`, `.lua`, `.toml`, `.json`, `.yaml`).
- 4 spaces for C-like file extensions.

Lua formatting in Neovim config follows `dot_config/nvim/stylua.toml` (spaces, width 2, line width 120).

Template/script naming should stay descriptive and lifecycle-based, e.g. `.chezmoiscripts/run_onchange_install-packages.sh.tmpl`.

## Testing Guidelines
There is no formal automated test suite in this repo. Validate changes with:

- `chezmoi diff` before apply.
- `chezmoi apply` to ensure templates render and hooks execute cleanly.
- Targeted smoke checks for affected tools (example: start Fish or Neovim after config updates).

For script changes, prefer idempotent logic so repeated `chezmoi apply` runs are safe.

## Commit & Pull Request Guidelines
Recent history favors short, imperative commit messages (examples: `fix conda bug`, `add oh-my-tmux`, `Implement Bitwarden-based CLI auto-login feature...`).

- Keep subject lines concise and action-oriented.
- Group related dotfile/script updates into one commit.
- In PRs, include: purpose, OS impact (macOS/Ubuntu), changed paths, and manual verification steps.
- Add screenshots only when UI-facing configs (for example terminal prompt/theme) visibly change.
