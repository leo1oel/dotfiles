if type -q fzf
    # `fzf --fish` (fzf >= 0.48) emits init code that also needs a modern fish
    # (>= 3.4); an ancient system fish chokes on it with
    # "'return' outside of function definition". Gate on the fish version so we
    # never source it into a fish too old to parse it.
    set -l _fmaj (string split '.' -- $version)[1]
    set -l _fmin (string split '.' -- $version)[2]
    set -l _fish_ok false
    if test "$_fmaj" -gt 3 2>/dev/null
        set _fish_ok true
    else if test "$_fmaj" -eq 3 -a "$_fmin" -ge 4 2>/dev/null
        set _fish_ok true
    end

    if test "$_fish_ok" = true; and fzf --fish &>/dev/null
        # New way: fzf supports --fish option (and fish is new enough)
        fzf --fish | source
    else if test -f /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish
        source /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish
    else if test -f ~/.fzf/shell/key-bindings.fish
        source ~/.fzf/shell/key-bindings.fish
    end

    # Unbind Ctrl-T to avoid Zellij conflict
    bind -e \ct 2>/dev/null
    bind -e \cr 2>/dev/null
    bind -e \ec 2>/dev/null

    # Rebind Ctrl-Alt-<key> for fzf (if functions exist)
    type -q fzf-file-widget; and bind ctrl-alt-t fzf-file-widget
    type -q fzf-cd-widget; and bind ctrl-alt-d fzf-cd-widget
    type -q fzf-history-widget; and bind ctrl-alt-h fzf-history-widget
else
    echo "fzf was not installed."
end
