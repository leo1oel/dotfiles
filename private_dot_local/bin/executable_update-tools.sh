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
# fish shell — keep the no-sudo ~/.local/bin standalone build at latest (Linux).
# System/PPA fish is handled by apt; Homebrew fish by `brew upgrade` below.
#################
if [ "$OS" = "Linux" ] && [ -x "$HOME/.local/bin/fish" ] && command -v curl >/dev/null 2>&1; then
    fish_latest=$(curl -fsSL https://api.github.com/repos/fish-shell/fish-shell/releases/latest 2>/dev/null | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/')
    fish_current=$("$HOME/.local/bin/fish" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -n "$fish_latest" ] && [ "$fish_latest" != "$fish_current" ]; then
        echo "🐟 Updating fish ${fish_current:-?} → ${fish_latest}..."
        case "$(uname -m)" in
            aarch64|arm64) fish_arch="aarch64" ;;
            *)             fish_arch="x86_64" ;;
        esac
        if curl -fsSL "https://github.com/fish-shell/fish-shell/releases/download/${fish_latest}/fish-${fish_latest}-linux-${fish_arch}.tar.xz" -o /tmp/fish.tar.xz; then
            rm -rf /tmp/fish-dl && mkdir -p /tmp/fish-dl
            if tar -xf /tmp/fish.tar.xz -C /tmp/fish-dl 2>/dev/null; then
                fish_bin=$(find /tmp/fish-dl -type f -name fish | head -1)
                if [ -n "$fish_bin" ]; then
                    chmod +x "$fish_bin" && mv "$fish_bin" "$HOME/.local/bin/fish"
                    echo "✅ fish updated to ${fish_latest}"
                fi
            fi
            rm -rf /tmp/fish.tar.xz /tmp/fish-dl
        else
            echo "⚠️  fish ${fish_latest} download failed (keeping ${fish_current:-current})"
        fi
    fi
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
