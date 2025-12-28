
if type -q zoxide
    # Initialize zoxide with error handling
    # Suppress errors when Fish data files are missing (non-standard installation)
    if zoxide init fish --no-cmd 2>/dev/null | source
        # Successfully initialized - you can use 'z' for smart directory jumping
    else
        # Fallback: just set up the basic 'z' command without cd override
        set -gx _ZO_DATA_DIR $HOME/.local/share/zoxide
        function z
            set -l result (zoxide query --exclude $PWD -- $argv)
            and cd $result
        end
    end
else
    # zoxide not installed - silently skip (not an error)
end
