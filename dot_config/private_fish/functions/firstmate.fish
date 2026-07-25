function firstmate --description 'Open herdr with a captain Claude Code (UPSTREAM firstmate orchestrator)'
    # Where the upstream firstmate clone lives. FIRSTMATE_DIR is remembered as a universal
    # variable, asked once. This is the sibling of `nemo` (the herdr-native fork): `nemo`
    # runs leo1oel/nemo on herdr-native worktrees; `firstmate` runs kunchenguid/firstmate
    # upstream, which uses herdr for SESSIONS but treehouse for worktrees (installed below).
    # The two coexist on one herdr server via distinct captain agent names (firstmate vs
    # captain) and separate clone dirs, so their state/data never mix.
    set -l fm_dir
    if set -q FIRSTMATE_DIR; and test -n "$FIRSTMATE_DIR"
        set fm_dir $FIRSTMATE_DIR
    else
        echo "firstmate: FIRSTMATE_DIR is not configured."
        echo "Enter an absolute directory for the upstream firstmate orchestrator - an empty or"
        echo "not-yet-existing directory with enough disk (can be outside ~, e.g. /tmp/firstmate)."
        echo "The clone goes HERE, so do not point it at a populated directory like /tmp itself:"
        echo -n "firstmate dir> "
        read -l answer
        if test -z "$answer"
            echo "firstmate: no directory given; aborting." >&2
            return 1
        end
        set -U FIRSTMATE_DIR $answer
        set fm_dir $answer
        echo "firstmate: saved FIRSTMATE_DIR=$answer"
    end

    if not type -q herdr
        echo "firstmate: herdr is not on PATH; install it first (see ~/.local/bin/update-tools.sh)." >&2
        return 1
    end
    if not type -q claude
        echo "firstmate: claude is not on PATH; install Claude Code first." >&2
        return 1
    end

    # Upstream firstmate's DEFAULT branch (main) is what we want here (unlike the fork,
    # whose herdr port lives on a non-default branch). Clone it on first use and keep an
    # existing clone fast-forwarded to the latest upstream main.
    if not test -d "$fm_dir/.git"; and test (count (command ls -A "$fm_dir" 2>/dev/null)) -gt 0
        echo "firstmate: '$fm_dir' already exists and is not empty, so git cannot clone into it." >&2
        echo "firstmate: point FIRSTMATE_DIR at an empty or new directory instead, e.g.:" >&2
        echo "      set -U FIRSTMATE_DIR $fm_dir/firstmate" >&2
        echo "firstmate: then run 'firstmate' again.  (to re-pick from scratch:  set -e FIRSTMATE_DIR)" >&2
        return 1
    end
    if not test -d "$fm_dir/.git"
        echo "firstmate: cloning kunchenguid/firstmate into $fm_dir ..."
        git clone https://github.com/kunchenguid/firstmate.git "$fm_dir"
        or begin
            echo "firstmate: clone failed." >&2
            return 1
        end
    else
        # Fast-forward to the latest upstream main. Non-fatal so an offline or
        # locally-modified clone still launches, but warn loudly instead of silently
        # running a stale checkout.
        set -l fm_pull_err (git -C "$fm_dir" pull --ff-only 2>&1)
        if test $status -ne 0
            echo "⚠️  firstmate: could not fast-forward $fm_dir; launching on the current (possibly stale) checkout." >&2
            echo "    Likely local changes/commits (diverged, needs a manual merge) or you are offline. git said:" >&2
            for line in $fm_pull_err
                echo "      $line" >&2
            end
            echo "    To sync: cd $fm_dir; git status   (then stash / commit / merge as needed)" >&2
        end
    end

    # Refresh the fleet tooling upstream firstmate needs, including treehouse (its worktree
    # provider). Only on a FRESH launch, not on reattach: re-running `firstmate` to reattach
    # a live captain stays fast, and self-updating herdr under an already-running server
    # would leave it on a deleted binary. A running firstmate captain == reattach.
    set -l captain_running 0
    if herdr agent list 2>/dev/null | string match -q '*"name":"firstmate"*'
        set captain_running 1
    end
    if test $captain_running -eq 0
        if test -x "$HOME/.local/bin/update-tools.sh"
            bash "$HOME/.local/bin/update-tools.sh" firstmate
        else
            # Updater missing (unusual): do the minimum a fresh upstream fleet needs inline.
            herdr integration install claude >/dev/null 2>&1
            herdr plugin install smarzban/herdr-file-viewer --yes >/dev/null 2>&1
            if not type -q treehouse
                echo "firstmate: installing treehouse (upstream worktree provider)..."
                curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh >/dev/null 2>&1 \
                    || echo "⚠️  firstmate: treehouse install failed; upstream worktrees will not work." >&2
            end
        end
    else
        herdr integration install claude >/dev/null 2>&1
        if test -x "$HOME/.local/bin/update-tools.sh"
            bash "$HOME/.local/bin/update-tools.sh" firstmate-reattach
        end
    end

    # Ensure the herdr server is up so the captain can be seeded before we attach.
    if not herdr status server 2>/dev/null | string match -q '*status: running*'
        herdr server >/dev/null 2>&1 &
        disown
        for i in (seq 1 20)
            herdr status server 2>/dev/null | string match -q '*status: running*'; and break
            sleep 0.3
        end
    end

    # Pick up any config.toml changes on the running server.
    herdr server reload-config >/dev/null 2>&1 || true

    # Start the captain once: a Claude Code in the upstream firstmate repo, with the herdr
    # backend so every crewmate it dispatches shows up as its own herdr pane. The captain
    # agent is named `firstmate` (not `captain`) so it never collides with a `nemo` captain
    # on the same herdr server.
    # As root (a disposable sandbox container) claude refuses its bypass-permissions mode
    # unless IS_SANDBOX=1 is set, so pass it explicitly here too.
    set -l captain_env --env FM_BACKEND=herdr
    if test (id -u) -eq 0
        set captain_env $captain_env --env IS_SANDBOX=1
    end
    if not herdr agent list 2>/dev/null | string match -q '*"name":"firstmate"*'
        herdr agent start firstmate --cwd "$fm_dir" $captain_env --focus -- claude >/dev/null
    end

    # Attach (takes over this terminal until you detach with the herdr prefix, default ctrl+b q).
    herdr
end
