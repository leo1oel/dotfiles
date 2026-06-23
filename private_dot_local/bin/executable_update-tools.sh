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

    # Ensure a modern python3 (>= 3.8) is the first `python3` on PATH. HPC login
    # nodes often ship an ancient system python3 (e.g. 3.6.8) that breaks hooks
    # needing 3.7+ (herdr's state reporter uses time.time_ns()). Idempotent: only
    # acts when python3 is missing or older than 3.8, then fronts a uv-managed
    # standalone python via ~/.local/bin (no compile, fast). Leaves a machine that
    # already has a modern system python3 untouched.
    _need_py=1
    if command -v python3 >/dev/null 2>&1; then
        _pyv=$(python3 -c 'import sys; print(sys.version_info[0]*100 + sys.version_info[1])' 2>/dev/null || echo 0)
        [ "${_pyv:-0}" -ge 308 ] 2>/dev/null && _need_py=0
    fi
    if [ "$_need_py" = 1 ]; then
        echo "🐍 Installing a modern python3 via uv (system python3 missing or < 3.8)..."
        uv python install 3.12 >/dev/null 2>&1 || echo "⚠️  uv python install failed"
        _uvpy=$(uv python find 3.12 2>/dev/null || true)
        if [ -n "$_uvpy" ] && [ -x "$_uvpy" ]; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$_uvpy" "$HOME/.local/bin/python3"
            ln -sf "$_uvpy" "$HOME/.local/bin/python"
            echo "✅ python3 -> $_uvpy"
        fi
    fi
fi

#################
# Media / CLI tools that need compiled C libs (pdftoppm/poppler for yazi's PDF
# preview, ffmpegthumbnailer, chafa, imagemagick) plus a few Rust tools (ripgrep,
# fd, 7z). On a no-sudo cluster apt/dnf is unavailable, so these are delivered via
# a conda-forge env built by micromamba — a single static, relocatable binary that
# bundles its own libs, so it needs no sudo and ignores the system glibc. macOS
# gets all of these from Homebrew (Brewfile), so this is Linux-only. Idempotent:
# skips entirely once pdftoppm is on PATH or the env already exists. The env lives
# under $MAMBA_ROOT_PREFIX (set to the big filesystem by 51_micromamba.fish.tmpl);
# 51_micromamba.fish fronts its bin/ onto PATH for interactive shells.
#################
if [ "$OS" = "Linux" ] && ! command -v pdftoppm >/dev/null 2>&1; then
    # Resolve where the env lives. Prefer MAMBA_ROOT_PREFIX (51_micromamba.fish
    # pins it to the big disk), but that conf is not yet sourced on the same `up`
    # run that just pulled it, so fall back to deriving the big disk from NEMO_DIR
    # (already exported) before the small-~ default — these envs are hundreds of MB
    # and would blow an HPC ~ quota.
    if [ -n "${MAMBA_ROOT_PREFIX:-}" ]; then
        _tools_root="$MAMBA_ROOT_PREFIX"
    elif [ -n "${NEMO_DIR:-}" ]; then
        _tools_root="$(dirname "$NEMO_DIR")/mamba"
    else
        _tools_root="$HOME/.local/share/mamba"
    fi
    if [ -x "$_tools_root/envs/tools/bin/pdftoppm" ]; then
        :   # env already built — fish puts it on PATH in interactive shells
    elif command -v curl >/dev/null 2>&1; then
        _mamba="$HOME/.local/bin/micromamba"
        command -v micromamba >/dev/null 2>&1 && _mamba="$(command -v micromamba)"
        if [ ! -x "$_mamba" ]; then
            echo "📦 Installing micromamba (no-sudo media-tools delivery)..."
            case "$(uname -m)" in
                aarch64|arm64) _mm_arch="linux-aarch64" ;;
                *)             _mm_arch="linux-64" ;;
            esac
            mkdir -p "$HOME/.local/bin"
            if curl -fsSL "https://micro.mamba.pm/api/micromamba/${_mm_arch}/latest" \
                | tar -xj -C "$HOME/.local" bin/micromamba 2>/dev/null; then
                chmod +x "$HOME/.local/bin/micromamba"
                _mamba="$HOME/.local/bin/micromamba"
            else
                echo "⚠️  micromamba download failed; skipping media tools"
                _mamba=""
            fi
        fi
        if [ -n "${_mamba:-}" ] && [ -x "$_mamba" ]; then
            echo "🎬 Building conda-forge tools env (poppler/ffmpegthumbnailer/chafa/imagemagick/ripgrep/fd/7z)..."
            "$_mamba" create -y -r "$_tools_root" -n tools -c conda-forge \
                poppler ffmpegthumbnailer chafa imagemagick ripgrep fd-find sevenzip \
                >/dev/null 2>&1 \
                && echo "✅ tools env -> $_tools_root/envs/tools/bin" \
                || echo "⚠️  tools env build failed"
        fi
    fi
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
# Re-add herdr's Claude integration hook (live idle/working/done state in herdr
# panes). chezmoi manages ~/.claude/settings.json as a full file and overwrites
# it on every apply, so this hook is owned by herdr + re-applied here and by the
# `nemo` launcher, never preserved in the chezmoi source. Idempotent; no-op
# outside a herdr pane.
if command -v herdr >/dev/null 2>&1; then
    echo "🐑 Re-applying herdr Claude integration..."
    herdr integration install claude >/dev/null 2>&1 || echo "⚠️  herdr claude integration install failed"
fi

#################
# firstmate (nemo) crew tooling: no-mistakes (validation) + axi helpers (gh / browser /
# review). Install if missing (then run its one-time `setup hooks`), update to latest if
# already present. This is what fm-bootstrap.sh used to check; provisioning lives here now.
#################
if command -v npm >/dev/null 2>&1; then
    echo "⚓ Updating firstmate axi tools (gh-axi, chrome-devtools-axi, lavish-axi)..."
    for axi in gh-axi chrome-devtools-axi lavish-axi; do
        if command -v "$axi" >/dev/null 2>&1; then
            npm install -g "$axi@latest" >/dev/null 2>&1 || echo "⚠️  $axi update failed"
        else
            npm install -g "$axi@latest" >/dev/null 2>&1 && "$axi" setup hooks >/dev/null 2>&1 \
                || echo "⚠️  $axi install failed"
        fi
    done
fi
if command -v curl >/dev/null 2>&1; then
    echo "✅ Updating no-mistakes..."
    curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh \
        || echo "⚠️  no-mistakes update failed"
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
