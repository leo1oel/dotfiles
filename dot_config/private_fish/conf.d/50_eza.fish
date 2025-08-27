
if type -q eza
    set -l EZA_CMD "eza --group-directories-first --icons=auto --time-style relative"
    alias l="$EZA_CMD"
    alias ls="eza"
    alias la="$EZA_CMD -a"
    alias ll="$EZA_CMD -lh --git"
    alias lll="$EZA_CMD -lha --git"
    alias llll="$EZA_CMD -lhaiHgM --git --extended --context"
else
    echo "EZA was not installed."
end
