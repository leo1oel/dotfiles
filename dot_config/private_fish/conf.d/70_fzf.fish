
if type -q fzf
    fzf --fish | source
else
    echo "fzf was not installed."
end
