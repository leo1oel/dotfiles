#!/usr/bin/env bash
# Upgrade all CLI dev/AI tools to their latest versions.
#
# Run directly:        update-tools.sh
# Or via fish wrapper: `up`  (runs `chezmoi update` first, then this script)
#
# Safe to run any time: every step is guarded by `command -v` and failures in
# one tool never abort the others.

set -u

OS="$(uname -s)"
echo "🔄 Upgrading CLI tools (${OS})..."

# Make user-local tool paths visible regardless of which shell invoked us.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/fnm:$PATH"

# Bring fnm-managed Node onto PATH (needed for the npm global upgrades below).
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash 2>/dev/null)" || true
fi

#################
# npm global AI/dev tools (Claude Code, Codex)
#################
if command -v npm >/dev/null 2>&1; then
    echo "📦 Upgrading npm globals: Claude Code, Codex..."
    npm install -g \
        @anthropic-ai/claude-code@latest \
        @openai/codex@latest \
        || echo "⚠️  Some npm globals failed to upgrade"
else
    echo "ℹ️  npm not found; skipping Claude Code / Codex upgrade"
fi

#################
# Claude Code skills — keep the Anthropic skill-creator skill at latest
# (via the `skills` CLI: https://github.com/vercel-labs/skills)
#################
if command -v npx >/dev/null 2>&1; then
    echo "🧩 Updating skill-creator skill..."
    npx -y skills add anthropics/skills --skill skill-creator --agent claude-code --global --yes \
        || echo "⚠️  skill-creator skill update failed"
else
    echo "ℹ️  npx not found; skipping skill-creator skill update"
fi

#################
# uv + uv-managed Python tools (huggingface-hub, wandb, gpustat, ...)
#################
if command -v uv >/dev/null 2>&1; then
    echo "🐍 Upgrading uv and uv tools..."
    uv self update 2>/dev/null || true            # no-op if uv is package-managed
    uv tool upgrade --all || echo "⚠️  Some uv tools failed to upgrade"
fi

#################
# herdr (terminal multiplexer for AI agents)
#################
if command -v curl >/dev/null 2>&1; then
    echo "🐑 Updating herdr..."
    curl -fsSL https://herdr.dev/install.sh | sh || echo "⚠️  herdr update failed"
fi

#################
# Homebrew (macOS) — upgrades everything in the Brewfile and more
#################
if [ "$OS" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
    echo "🍺 Upgrading Homebrew packages..."
    brew update && brew upgrade || echo "⚠️  brew upgrade reported errors"
fi

#################
# chezmoi self (standalone binary installs on Linux)
#################
if command -v chezmoi >/dev/null 2>&1; then
    chezmoi upgrade 2>/dev/null || true
fi

echo "✅ Tool upgrade complete."
