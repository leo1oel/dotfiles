if status is-interactive
    if type -q fastfetch
        fastfetch
    else if type -q neofetch
        neofetch
    end
end
