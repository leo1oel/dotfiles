function nemo --description 'Open herdr with a captain Claude Code (nemo / firstmate orchestrator)'
    # Where the nemo fork lives. NEMO_DIR is normally exported by the fish config from the
    # chezmoi prompt (conf.d/95_nemo.fish). If it is unset (prompt skipped, or an older
    # machine), ask once and remember it as a universal variable.
    set -l nemo_dir
    if set -q NEMO_DIR; and test -n "$NEMO_DIR"
        set nemo_dir $NEMO_DIR
    else
        echo "nemo: NEMO_DIR is not configured."
        echo "Enter an absolute directory for the nemo orchestrator - an empty or not-yet-existing"
        echo "directory with enough disk (can be outside ~, e.g. /tmp/nemo). The clone goes HERE,"
        echo "so do not point it at a populated directory like /tmp itself:"
        echo -n "nemo dir> "
        read -l answer
        if test -z "$answer"
            echo "nemo: no directory given; aborting." >&2
            return 1
        end
        set -U NEMO_DIR $answer
        set nemo_dir $answer
        echo "nemo: saved NEMO_DIR=$answer"
    end

    if not type -q herdr
        echo "nemo: herdr is not on PATH; install it first (see ~/.local/bin/update-tools.sh)." >&2
        return 1
    end
    if not type -q claude
        echo "nemo: claude is not on PATH; install Claude Code first." >&2
        return 1
    end

    # The herdr port lives on the `herdr-backend` branch. The fork's DEFAULT branch
    # (main) still tracks upstream firstmate, which uses treehouse instead of herdr —
    # so a plain clone/checkout makes the captain ask to install treehouse. Pin the
    # branch here: clone it on first use, and switch an existing clone onto it.
    set -l nemo_branch herdr-backend
    # NEMO_DIR is the clone location itself, so it must be empty or not yet exist (an
    # existing nemo clone is fine). Cloning into a populated non-git dir like /tmp fails
    # with a cryptic git error, so catch that here with an actionable message instead.
    if not test -d "$nemo_dir/.git"; and test (count (command ls -A "$nemo_dir" 2>/dev/null)) -gt 0
        echo "nemo: '$nemo_dir' already exists and is not empty, so git cannot clone into it." >&2
        echo "nemo: point NEMO_DIR at an empty or new directory instead, e.g.:" >&2
        echo "      set -U NEMO_DIR $nemo_dir/nemo" >&2
        echo "nemo: then run 'nemo' again.  (to re-pick from scratch:  set -e NEMO_DIR)" >&2
        return 1
    end
    if not test -d "$nemo_dir/.git"
        echo "nemo: cloning leo1oel/nemo ($nemo_branch) into $nemo_dir ..."
        git clone --branch $nemo_branch https://github.com/leo1oel/nemo.git "$nemo_dir"
        or begin
            echo "nemo: clone failed." >&2
            return 1
        end
    else
        # Keep an existing clone on the herdr port AND current with pushed fixes.
        if test (git -C "$nemo_dir" rev-parse --abbrev-ref HEAD) != $nemo_branch
            echo "nemo: switching $nemo_dir onto the $nemo_branch branch (herdr port) ..."
            git -C "$nemo_dir" fetch origin $nemo_branch
            and git -C "$nemo_dir" checkout $nemo_branch
            or echo "nemo: could not switch to $nemo_branch; fix $nemo_dir by hand." >&2
        end
        # Fast-forward to the latest pushed herdr-backend. Non-fatal so an offline or
        # locally-modified clone still launches, but warn loudly instead of silently
        # running a stale checkout: a forgotten local edit or commit here blocks the
        # fast-forward and needs a manual merge, so surface that rather than hide it.
        set -l nemo_pull_err (git -C "$nemo_dir" pull --ff-only 2>&1)
        if test $status -ne 0
            echo "⚠️  nemo: could not fast-forward $nemo_dir; launching on the current (possibly stale) checkout." >&2
            echo "    Likely local changes/commits (diverged, needs a manual merge) or you are offline. git said:" >&2
            for line in $nemo_pull_err
                echo "      $line" >&2
            end
            echo "    To sync: cd $nemo_dir; git status   (then stash / commit / merge as needed)" >&2
        end
    end

    # Refresh the fleet tooling that the captain + crew rely on: npm AI globals
    # (Claude Code, Codex), Leo agent skills, herdr (self-update + Claude integration
    # + file-viewer plugin), and the firstmate axi/no-mistakes crew tooling. This is
    # the `nemo` subset of update-tools.sh — a fresh nemo box or sandbox container may
    # only ever run `nemo` (never `up`), so it must be able to provision everything the
    # fleet needs on its own. `up` still owns the full CLI upgrade; axi/no-mistakes now
    # live here only (see update-tools.sh mode dispatch).
    #
    # Only do this on a FRESH launch, not on reattach: re-running `nemo` to reattach a
    # live captain should stay fast, and self-updating herdr under an already-running
    # server would leave it on a deleted binary (the stale-inode / exit-127 trap). A
    # running captain == reattach; anything else (no server, or a server with no
    # captain) == fresh start.
    set -l captain_running 0
    if herdr agent list 2>/dev/null | string match -q '*"name":"captain"*'
        set captain_running 1
    end
    if test $captain_running -eq 0
        if test -x "$HOME/.local/bin/update-tools.sh"
            bash "$HOME/.local/bin/update-tools.sh" nemo
        else
            # Updater missing (unusual): do the minimum a fresh fleet needs inline so the
            # config.toml prefix+f / prefix+shift+f keybindings still have a plugin to invoke.
            herdr integration install claude >/dev/null 2>&1
            herdr plugin install smarzban/herdr-file-viewer --yes >/dev/null 2>&1
        end
    else
        # Reattach: keep the live sidebar integration current (cheap, local), then refresh
        # just the crew tooling that changes often and is safe to update under a running
        # server: Leo agent skills + firstmate axi. The herdr self-update (would swap the
        # binary under the live server) and the npm AI globals (heavy; the running captain
        # would not pick them up) are deliberately left for the next fresh launch.
        herdr integration install claude >/dev/null 2>&1
        if test -x "$HOME/.local/bin/update-tools.sh"
            bash "$HOME/.local/bin/update-tools.sh" nemo-reattach
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

    # Pick up any config.toml changes (e.g. the worktree directory) on the running server.
    herdr server reload-config >/dev/null 2>&1 || true

    # Start the captain once: a Claude Code in the nemo repo, with the herdr backend so every
    # crewmate it dispatches shows up as its own herdr pane.
    # As root (a disposable sandbox container) claude refuses its bypass-permissions mode
    # unless IS_SANDBOX=1 is set, so pass it explicitly here too - this covers the captain
    # agent even when the already-running herdr server was started without it.
    # (conf.d/30_claude_sandbox.fish sets it for fresh servers and the crewmates they spawn.)
    set -l captain_env --env FM_BACKEND=herdr
    if test (id -u) -eq 0
        set captain_env $captain_env --env IS_SANDBOX=1
    end
    if not herdr agent list 2>/dev/null | string match -q '*"name":"captain"*'
        herdr agent start captain --cwd "$nemo_dir" $captain_env --focus -- claude >/dev/null
    end

    # Attach (takes over this terminal until you detach with the herdr prefix, default ctrl+b q).
    herdr
end
