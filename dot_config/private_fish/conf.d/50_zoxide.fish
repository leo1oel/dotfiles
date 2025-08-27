
if type -q zoxide
    zoxide init fish | source
    alias cd="z"
else
    echo "zoxide was not installed."
end
