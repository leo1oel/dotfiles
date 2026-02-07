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

    tmux set-option -g default-terminal "$requested_term" >/dev/null 2>&1

    set -l in_tmux false
    if set -q TMUX
        if tmux display-message -p "#S" >/dev/null 2>&1
            set in_tmux true
        end
    end

    set -l session "yn"
    if test "$in_tmux" = true
        set session (tmux display-message -p "#S")
    end

    if not tmux has-session -t "$session" 2>/dev/null
        tmux new-session -d -s "$session" -c "$target" "yazi ."
    end

    set -l win_index (tmux list-windows -t "$session" -F "#{window_index}" 2>/dev/null | head -n1)
    if test -z "$win_index"
        tmux new-window -t "$session" -n main -c "$target" "yazi ."
        set win_index (tmux list-windows -t "$session" -F "#{window_index}" | head -n1)
    end

    tmux respawn-pane -k -t "$session":"$win_index".0 -c "$target" "yazi ."
    if test (tmux list-panes -t "$session":"$win_index" | wc -l | string trim) -lt 2
        tmux split-window -h -t "$session":"$win_index" -c "$target" "nvim ."
    else
        tmux respawn-pane -k -t "$session":"$win_index".1 -c "$target" "nvim ."
    end
    tmux select-layout -t "$session":"$win_index" even-horizontal >/dev/null 2>&1
    tmux select-pane -t "$session":"$win_index".0

    if test "$in_tmux" = true
        return
    end
    tmux attach -t "$session"
end
