if status is-interactive
    if type -q neofetch
        neofetch
    else if type -q fastfetch
        fastfetch 2>/dev/null
    end
end
