
if type -q zoxide
    zoxide init fish | source
else
    echo "zoxide was not installed."
end
