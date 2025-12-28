
if type -q zoxide
    # Set __fish_data_dir to user directory if not set or doesn't contain cd.fish
    if not test -f "$__fish_data_dir/functions/cd.fish"
        set -gx __fish_data_dir "$HOME/.local/share/fish"
    end

    # Initialize zoxide (cd.fish is created by installation script)
    zoxide init fish | source
end
