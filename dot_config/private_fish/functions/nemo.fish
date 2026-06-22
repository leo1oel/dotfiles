function nemo --description 'Open herdr with a captain agent (claude|codex; default claude) running the nemo orchestrator'
    # Captain harness: `nemo` (claude), `nemo codex`, or set NEMO_AGENT. Crewmates follow the
    # captain automatically (nemo's config/crew-harness stays "default" -> fm-harness detect_own),
    # so this one argument switches the whole fleet.
    set -l agent claude
    if set -q argv[1]
        set agent $argv[1]
    else if set -q NEMO_AGENT
        set agent $NEMO_AGENT
    end
    switch $agent
        case claude codex
        case '*'
            echo "nemo: unknown agent '$agent' (use 'claude' or 'codex')." >&2
            return 1
    end

    # Where the nemo fork lives; override with NEMO_DIR. Cloned on first use.
    set -l nemo_dir
    if set -q NEMO_DIR
        set nemo_dir $NEMO_DIR
    else
        set nemo_dir "$HOME/CascadeProjects/nemo"
    end

    if not type -q herdr
        echo "nemo: herdr is not on PATH; install it first (see ~/.local/bin/update-tools.sh)." >&2
        return 1
    end
    if not type -q $agent
        echo "nemo: $agent is not on PATH; install it first." >&2
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

    # Keep the herdr <-> agent integration current (idempotent; gives live sidebar state).
    herdr integration install $agent >/dev/null 2>&1

    # Ensure the herdr server is up so the captain can be seeded before we attach.
    if not herdr status server 2>/dev/null | string match -q '*status: running*'
        herdr server >/dev/null 2>&1 &
        disown
        for _ in (seq 1 20)
            herdr status server 2>/dev/null | string match -q '*status: running*'; and break
            sleep 0.3
        end
    end

    # Start the captain once: the chosen agent in the nemo repo, with the herdr backend so every
    # crewmate it dispatches shows up as its own herdr pane.
    if not herdr agent list 2>/dev/null | string match -q '*"name":"captain"*'
        herdr agent start captain --cwd "$nemo_dir" --env FM_BACKEND=herdr --focus -- $agent >/dev/null
    end

    # Attach (takes over this terminal until you detach with the herdr prefix, default ctrl+b q).
    herdr
end
