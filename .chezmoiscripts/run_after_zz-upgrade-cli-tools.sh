#!/bin/bash
# Runs after EVERY `chezmoi apply` / `chezmoi update`.
# Brings CLI tools to latest AND installs any that are missing:
#   Claude Code, Codex, OpenCommit, herdr, the skill-creator skill, uv tools
#   (+ brew upgrade on macOS). The heavy lifting lives in ~/.local/bin/update-tools.sh.
#
# Skip it (e.g. while iterating on dotfiles) with:
#   DOTFILES_SKIP_TOOL_UPGRADE=1 chezmoi apply
if [ "${DOTFILES_SKIP_TOOL_UPGRADE:-}" = "1" ]; then
    echo "⏭️  DOTFILES_SKIP_TOOL_UPGRADE=1 — skipping CLI tool upgrade."
    exit 0
fi

UPDATER="$HOME/.local/bin/update-tools.sh"
if [ -x "$UPDATER" ]; then
    "$UPDATER" || echo "⚠️  Some tool upgrades reported errors (continuing)."
else
    echo "ℹ️  $UPDATER not present yet; it will run on the next apply."
fi
