function nemo --description 'Open herdr with a captain Claude Code (nemo / firstmate orchestrator)'
    # Where the nemo fork lives. NEMO_DIR is normally exported by the fish config from the
    # chezmoi prompt (conf.d/95_nemo.fish). If it is unset (prompt skipped, or an older
    # machine), ask once and remember it as a universal variable.
    set -l nemo_dir
    if set -q NEMO_DIR; and test -n "$NEMO_DIR"
        set nemo_dir $NEMO_DIR
    else
        echo "nemo: NEMO_DIR is not configured."
        echo "Enter an absolute directory for the nemo orchestrator (somewhere with enough disk; can be outside ~):"
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

    # Clone the fork on first use.
    if not test -d "$nemo_dir/.git"
        echo "nemo: cloning leo1oel/nemo into $nemo_dir ..."
        git clone https://github.com/leo1oel/nemo.git "$nemo_dir"
        or begin
            echo "nemo: clone failed." >&2
            return 1
        end
    end

    # Keep the herdr <-> Claude integration current (idempotent; gives live sidebar state).
    herdr integration install claude >/dev/null 2>&1

    # Ensure the herdr server is up so the captain can be seeded before we attach.
    if not herdr status server 2>/dev/null | string match -q '*status: running*'
        herdr server >/dev/null 2>&1 &
        disown
        for _ in (seq 1 20)
            herdr status server 2>/dev/null | string match -q '*status: running*'; and break
            sleep 0.3
        end
    end

    # Pick up any config.toml changes (e.g. the worktree directory) on the running server.
    herdr server reload-config >/dev/null 2>&1 || true

    # Start the captain once: a Claude Code in the nemo repo, with the herdr backend so every
    # crewmate it dispatches shows up as its own herdr pane.
    if not herdr agent list 2>/dev/null | string match -q '*"name":"captain"*'
        herdr agent start captain --cwd "$nemo_dir" --env FM_BACKEND=herdr --focus -- claude >/dev/null
    end

    # Attach (takes over this terminal until you detach with the herdr prefix, default ctrl+b q).
    herdr
end
