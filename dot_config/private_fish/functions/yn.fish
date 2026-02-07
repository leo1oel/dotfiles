function yn --description "Open left yazi and right nvim in tmux"
    set -l target (pwd)
    if test (count $argv) -gt 0
        set target $argv[1]
    end

    if not test -d "$target"
        echo "yn: directory not found: $target"
        return 1
    end

    if not type -q tmux
        echo "yn: tmux is not installed"
        return 1
    end

    set -l requested_term "$TERM"
    if test -z "$requested_term"
        set requested_term "xterm-256color"
    end

    if not infocmp "$requested_term" >/dev/null 2>&1
        for fallback in xterm-256color screen-256color xterm
            if infocmp "$fallback" >/dev/null 2>&1
                set requested_term "$fallback"
                break
            end
        end
        echo "yn: TERM '$TERM' not supported here, using '$requested_term'"
    end
    set -lx TERM "$requested_term"

    if set -q TMUX
        tmux split-window -h -c "$target" "nvim ."
        tmux select-pane -L
        yazi "$target"
        return
    end

    set -l session "yn"
    if not tmux has-session -t "$session" 2>/dev/null
        tmux new-session -d -s "$session" -c "$target" "yazi ."
        tmux split-window -h -t "$session":0 -c "$target" "nvim ."
        tmux select-pane -t "$session":0.0
    end

    tmux attach -t "$session"
end
