#!/usr/bin/env bash
# Upgrade all CLI dev/AI tools to their latest versions.
#
# Run directly:        update-tools.sh                # full upgrade (what `up` runs)
# Run the nemo subset: update-tools.sh nemo           # fleet tooling (fresh `nemo` launch)
#                      update-tools.sh nemo-reattach  # safe subset (`nemo` reattach)
#   upstream firstmate: update-tools.sh firstmate     # nemo tooling + treehouse (fresh `firstmate`)
#                      update-tools.sh firstmate-reattach
# Or via fish wrapper: `up`  (runs `chezmoi update` first, then this script, full mode)
#
# Modes:
#   full  (default) — everything below EXCEPT the firstmate axi/no-mistakes crew
#                     tooling. That is fleet-specific and owned by the launcher now,
#                     so a box that never runs a fleet does not fetch it.
#   nemo            — everything the nemo (herdr-native fork) fleet needs fresh at a
#                     launch with no live server: npm AI globals, Leo agent skills,
#                     herdr (+ integration/plugins), and the axi crew tooling.
#   nemo-reattach   — the subset that is safe to refresh while a captain is already
#                     running: Leo agent skills + axi crew tooling. Skips the herdr
#                     self-update (would swap the binary under the live server) and the
#                     npm AI globals (heavy; the running captain would not pick them up).
#   firstmate       — like nemo, PLUS treehouse: upstream firstmate uses herdr for
#                     sessions but treehouse for worktrees. The `firstmate` launcher
#                     calls this fresh-start.
#   firstmate-reattach — same safe subset as nemo-reattach (treehouse needs no
#                     under-server refresh). The `firstmate` launcher calls this on reattach.
#
# Every group is a function so the two modes can share one implementation. Steps are
# guarded by `command -v`; a failure in one tool never aborts the others.

set -u

OS="$(uname -s)"

# Make user-local tool paths visible regardless of which shell invoked us.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/fnm:$PATH"

# Bring fnm-managed Node onto PATH (needed for the npm global upgrades below).
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash 2>/dev/null)" || true
fi

#################
# npm global AI/dev tools (Claude Code, Codex)
#################
upd_npm_globals() {
    if command -v npm >/dev/null 2>&1; then
        echo "📦 Upgrading npm globals: Claude Code, Codex..."
        npm install -g \
            @anthropic-ai/claude-code@latest \
            @openai/codex@latest \
            || echo "⚠️  Some npm globals failed to upgrade"
        # bibtex-tidy is needed by the bibcite CLI (its tidy step). Guarded so
        # machines that already have it (e.g. via brew) keep their copy.
        if ! command -v bibtex-tidy >/dev/null 2>&1; then
            echo "📚 Installing bibtex-tidy (needed by bibcite)..."
            npm install -g bibtex-tidy || echo "⚠️  bibtex-tidy install failed"
        fi
    else
        echo "ℹ️  npm not found; skipping Claude Code / Codex upgrade"
    fi
}

#################
# Agent skills — install Leo's personal skills repository globally to ALL detected
# agents (`--all` = --skill '*' --agent '*' -y). Eve and PromptScript only support
# project-local skills, so each run prints a harmless "does not support global skill
# installation" line for those two; every other detected agent (incl. Claude Code,
# what the nemo fleet runs on) installs fine. The CLI has no per-agent exclude, so an
# all-agents global install is the simplest option. (skills CLI: https://github.com/vercel-labs/skills)
# Use a temp npm cache here because some machines may have stale/root-owned
# ~/.npm cache entries from older npm versions.
#################
upd_leo_skills() {
    if command -v npx >/dev/null 2>&1; then
        echo "🧩 Updating Leo agent skills..."
        npm_config_cache="${npm_config_cache:-${TMPDIR:-/tmp}/npm-cache-${USER:-user}}" \
            npx -y skills add leo1oel/leo-agent-skills --global --all \
            || echo "⚠️  Leo agent skills update failed"
        # bibcite ships in its own repo (next to the bibcite-cli CLI it drives), not in
        # leo-agent-skills, so install it explicitly rather than via --all above. Same
        # harmless "does not support global skill installation" line for Eve/PromptScript.
        npm_config_cache="${npm_config_cache:-${TMPDIR:-/tmp}/npm-cache-${USER:-user}}" \
            npx -y skills add leo1oel/bibcite --skill bibcite --global --yes \
            || echo "⚠️  bibcite skill update failed"
    else
        echo "ℹ️  npx not found; skipping Leo agent skills update"
    fi
}

#################
# uv + uv-managed Python tools (huggingface-hub, wandb, gpustat, ...)
#################
upd_uv() {
    if command -v uv >/dev/null 2>&1; then
        echo "🐍 Upgrading uv and uv tools..."
        uv self update 2>/dev/null || true            # no-op if uv is package-managed
        uv tool upgrade --all || echo "⚠️  Some uv tools failed to upgrade"

        # Ensure bibcite (canonical BibTeX CLI; PyPI package: bibcite-cli) is
        # installed. The `command -v` guard keeps the dev machine's
        # `uv tool install --editable ~/CascadeProjects/bibcite` untouched;
        # PyPI installs get upgraded by the `uv tool upgrade --all` above.
        if ! command -v bibcite >/dev/null 2>&1; then
            echo "📚 Installing bibcite (bibcite-cli)..."
            uv tool install bibcite-cli || echo "⚠️  bibcite install failed"
        fi

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
}

#################
# Media / CLI tools that need compiled C libs (pdftoppm/poppler for yazi's PDF
# preview, ffmpeg, chafa, imagemagick) plus a few Rust tools (ripgrep,
# fd, 7z). On a no-sudo cluster apt/dnf is unavailable, so these are delivered via
# a conda-forge env built by micromamba — a single static, relocatable binary that
# bundles its own libs, so it needs no sudo and ignores the system glibc. macOS
# gets all of these from Homebrew (Brewfile), so this is Linux-only. Idempotent:
# skips entirely once pdftoppm is on PATH or the env already exists. The env lives
# under $MAMBA_ROOT_PREFIX (set to the big filesystem by 51_micromamba.fish.tmpl);
# 51_micromamba.fish fronts its bin/ onto PATH for interactive shells.
#################
upd_media_linux() {
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
                echo "🎬 Building conda-forge tools env (poppler/ffmpeg/chafa/imagemagick/ripgrep/fd/7z)..."
                "$_mamba" create -y -r "$_tools_root" -n tools -c conda-forge \
                    poppler ffmpeg chafa imagemagick ripgrep fd-find p7zip \
                    >/dev/null 2>&1 \
                    && echo "✅ tools env -> $_tools_root/envs/tools/bin" \
                    || echo "⚠️  tools env build failed"
            fi
        fi
    fi
}

#################
# fish shell — keep the no-sudo ~/.local/bin standalone build at latest (Linux).
# System/PPA fish is handled by apt; Homebrew fish by `brew upgrade` below.
#################
upd_fish_linux() {
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
}

#################
# herdr (terminal multiplexer for AI agents) — self-update, re-apply the Claude
# integration hook, install/update plugins, and bounce an idle server so the next
# launch runs the fresh binary. Shared by `up` (full) and `nemo` (fresh launch).
#################
upd_herdr() {
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

        # herdr plugins. file-viewer = read-only, git-aware file tree + diff/markdown/code
        # preview in a herdr split (keybindings live in herdr/config.toml). `plugin install`
        # downloads a prebuilt binary for our platform (macOS arm64 / linux x86_64), so no
        # Rust toolchain is needed; re-running it updates to the latest release. Idempotent.
        echo "🐑 Installing/updating herdr plugins (file-viewer)..."
        herdr plugin install smarzban/herdr-file-viewer --yes >/dev/null 2>&1 \
            || echo "⚠️  herdr file-viewer plugin install failed"

        # A herdr self-update (the curl install above) replaces the on-disk binary, but any
        # already-running server keeps executing the old, now-deleted inode. herdr then hands
        # plugins a HERDR_BIN_PATH like `~/.local/bin/herdr (deleted)`, so every plugin action that
        # shells back through it dies with exit 127 — e.g. the file-viewer split silently never
        # opens. `nemo` reuses a running server, so the stale one lingers until restarted. Bounce an
        # *idle* server here so the next `nemo` starts on the fresh binary+plugins; if a captain/crew
        # is live, only warn so we never kill running agents out from under the user.
        if herdr status server 2>/dev/null | grep -q running; then
            if herdr agent list 2>/dev/null | grep -q '"name"'; then
                echo "⚠️  herdr was updated but a server with live agents is still on the old binary."
                echo "    Plugin actions (file-viewer) will fail until you restart it:  herdr server stop; nemo"
            else
                echo "🐑 Restarting idle herdr server to pick up the update..."
                herdr server stop >/dev/null 2>&1 || true
            fi
        fi
    fi
}

#################
# glow (markdown renderer) — the herdr-file-viewer plugin uses it to render .md
# previews (diffs go through delta, code through bat). macOS installs it from the
# Brewfile; Linux has no sudo-free source for charmbracelet's glow (it is not in the
# default apt repos, and conda-forge `glow` is an unrelated genomics toolkit), so
# fetch the prebuilt binary from GitHub releases into ~/.local/bin. Idempotent:
# installs when missing and updates when a newer tag ships.
#################
upd_glow_linux() {
    if [ "$OS" = "Linux" ] && command -v curl >/dev/null 2>&1; then
        glow_latest=$(curl -fsSL https://api.github.com/repos/charmbracelet/glow/releases/latest 2>/dev/null | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/')
        glow_current=""
        if command -v glow >/dev/null 2>&1; then
            glow_current=$(glow --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        fi
        if [ -n "$glow_latest" ] && [ "$glow_latest" != "$glow_current" ]; then
            echo "📝 Updating glow ${glow_current:-missing} → ${glow_latest}..."
            case "$(uname -m)" in
                aarch64|arm64) glow_arch="arm64" ;;
                *)             glow_arch="x86_64" ;;
            esac
            if curl -fsSL "https://github.com/charmbracelet/glow/releases/download/v${glow_latest}/glow_${glow_latest}_Linux_${glow_arch}.tar.gz" -o /tmp/glow.tar.gz; then
                rm -rf /tmp/glow-dl && mkdir -p /tmp/glow-dl
                if tar -xf /tmp/glow.tar.gz -C /tmp/glow-dl 2>/dev/null; then
                    glow_bin=$(find /tmp/glow-dl -type f -name glow | head -1)
                    if [ -n "$glow_bin" ]; then
                        mkdir -p "$HOME/.local/bin"
                        chmod +x "$glow_bin" && mv "$glow_bin" "$HOME/.local/bin/glow"
                        echo "✅ glow ${glow_latest} -> ~/.local/bin/glow"
                    fi
                fi
                rm -rf /tmp/glow.tar.gz /tmp/glow-dl
            else
                echo "⚠️  glow ${glow_latest} download failed"
            fi
        fi
    fi
}

#################
# firstmate (nemo) crew tooling: no-mistakes (validation) + axi helpers (gh / browser /
# review). Install if missing (then run its one-time `setup hooks`), update to latest if
# already present. This is nemo-specific, so the `nemo` launcher owns it — `up` (full mode)
# no longer runs it, and a box that never launches nemo does not fetch it.
#################
upd_axi() {
    if command -v npm >/dev/null 2>&1; then
        echo "⚓ Updating firstmate axi tools (gh-axi, chrome-devtools-axi, lavish-axi, tasks-axi)..."
        for axi in gh-axi chrome-devtools-axi lavish-axi tasks-axi; do
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
}

#################
# treehouse (git worktree provider for UPSTREAM firstmate). Upstream uses herdr as a
# session provider only and treehouse for the actual worktrees, so the `firstmate`
# launcher needs it. The `nemo` herdr-native fork does NOT (herdr owns worktrees
# there), so this is firstmate-only. Re-run the installer on every fresh `firstmate`
# launch to stay current with upstream (same policy as herdr); it is only wired into
# the fresh mode, never firstmate-reattach, so it never swaps the binary under a live
# task. Non-fatal so an offline launch still proceeds.
#################
upd_treehouse() {
    command -v curl >/dev/null 2>&1 || return 0
    echo "🌳 Installing/updating treehouse (upstream firstmate worktree provider)..."
    curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh \
        || echo "⚠️  treehouse install/update failed"
}

#################
# quota-axi (upstream firstmate quota-aware dispatch). Upstream lists it as a required
# bootstrap tool and its dispatch selector calls `quota-axi --json` for the
# `select: "quota-balanced"` strategy (degrading to random selection if it is absent).
# firstmate-only: the `nemo` fork is Claude-only single-vendor, where quota-balancing
# has nothing to balance, so nemo deliberately does not install it. npm global, same
# class as the other axi tools; refreshed on both fresh and reattach launches.
#################
upd_quota_axi() {
    command -v npm >/dev/null 2>&1 || return 0
    echo "⚓ Updating quota-axi (upstream firstmate quota-aware dispatch)..."
    npm install -g quota-axi@latest >/dev/null 2>&1 || { echo "⚠️  quota-axi install/update failed"; return 0; }
    # Run its one-time hook setup if this axi tool provides it; harmless no-op otherwise.
    quota-axi setup hooks >/dev/null 2>&1 || true
}

#################
# Homebrew (macOS) — upgrades everything in the Brewfile and more
#################
upd_brew_macos() {
    if [ "$OS" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
        echo "🍺 Upgrading Homebrew packages..."
        brew update && brew upgrade || echo "⚠️  brew upgrade reported errors"
    fi
}

#################
# chezmoi self (standalone binary installs on Linux)
#################
upd_chezmoi() {
    if command -v chezmoi >/dev/null 2>&1; then
        chezmoi upgrade 2>/dev/null || true
    fi
}

#################
# OpenAlex API key — used by the `find-and-read-papers` skill (OpenAlex search / citation graph).
# Free key from https://openalex.org/settings/api. If we have neither an exported
# key nor the saved key file, prompt once (interactively only) and persist it to a
# 0600 file that 53_openalex.fish exports into every future shell. Skips silently
# in non-interactive runs (no TTY) and once the key is present.
#################
upd_openalex() {
    _oa_key_file="$HOME/.config/openalex/api_key"
    if [ -z "${OPENALEX_API_KEY:-}" ] && [ ! -s "$_oa_key_file" ] && [ -t 0 ]; then
        printf '🔑 OpenAlex API key not set. Paste it (free at https://openalex.org/settings/api), or press Enter to skip: '
        read -r _oa_key || _oa_key=""
        if [ -n "$_oa_key" ]; then
            mkdir -p "$(dirname "$_oa_key_file")"
            printf '%s\n' "$_oa_key" >"$_oa_key_file"
            chmod 600 "$_oa_key_file"
            echo "✅ Saved to $_oa_key_file; new shells will export OPENALEX_API_KEY."
        else
            echo "ℹ️  Skipped; literature search will use the keyless (rate-limited) pool."
        fi
    fi
}

#################
# Mode dispatch
#################
MODE="${1:-full}"
case "$MODE" in
    nemo)
        # Fresh launch (no live server). Everything the nemo fleet needs current.
        # axi/no-mistakes live here (not in `full`) because they are nemo crew tooling.
        echo "🔄 Refreshing nemo fleet tools (${OS})..."
        upd_npm_globals
        upd_leo_skills
        upd_herdr
        upd_axi
        echo "✅ Nemo fleet tools ready."
        ;;
    nemo-reattach)
        # Reattach (captain already running). Only the pieces safe to refresh under a
        # live server: skills + axi. herdr self-update and npm globals wait for a fresh
        # launch (see the header for why).
        echo "🔄 Refreshing nemo crew tooling (reattach)..."
        upd_leo_skills
        upd_axi
        echo "✅ Nemo crew tooling refreshed."
        ;;
    firstmate)
        # Fresh launch of UPSTREAM firstmate (kunchenguid/firstmate). Same fleet tooling
        # as nemo, plus treehouse (worktree provider) and quota-axi (quota-aware dispatch):
        # upstream uses herdr for sessions but treehouse for worktrees, and lists quota-axi
        # as a required bootstrap tool. Both are firstmate-only.
        echo "🔄 Refreshing upstream firstmate fleet tools (${OS})..."
        upd_npm_globals
        upd_leo_skills
        upd_herdr
        upd_treehouse
        upd_axi
        upd_quota_axi
        echo "✅ Upstream firstmate fleet tools ready."
        ;;
    firstmate-reattach)
        # Reattach to a live upstream firstmate. Same safe subset as nemo-reattach plus
        # quota-axi (an npm tool safe to refresh under a live server); treehouse is a
        # fresh-launch-only concern, skipped here to never swap the worktree binary.
        echo "🔄 Refreshing upstream firstmate crew tooling (reattach)..."
        upd_leo_skills
        upd_axi
        upd_quota_axi
        echo "✅ Upstream firstmate crew tooling refreshed."
        ;;
    full)
        echo "🔄 Upgrading CLI tools (${OS})..."
        upd_npm_globals
        upd_leo_skills
        upd_uv
        upd_media_linux
        upd_fish_linux
        upd_herdr
        upd_glow_linux
        # axi/no-mistakes intentionally NOT here — `nemo` owns the firstmate crew tooling.
        upd_brew_macos
        upd_chezmoi
        upd_openalex
        echo "✅ Tool upgrade complete."
        ;;
    *)
        echo "update-tools.sh: unknown mode '$MODE' (expected: full | nemo | nemo-reattach | firstmate | firstmate-reattach)" >&2
        exit 2
        ;;
esac
