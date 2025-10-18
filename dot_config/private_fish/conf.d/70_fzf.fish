if type -q fzf
    # Try to initialize fzf for fish
    # Check if fzf supports --fish option (fzf >= 0.48.0)
    if fzf --fish &>/dev/null
        # New way: fzf supports --fish option
        fzf --fish | source
    else
        # Fallback for older fzf versions
        if test -f /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish
            source /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish
        else if test -f ~/.fzf/shell/key-bindings.fish
            source ~/.fzf/shell/key-bindings.fish
        end
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
