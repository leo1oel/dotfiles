
if type -q direnv
    direnv hook fish | source
    set -g direnv_fish_mode eval_on_arrow
else
    echo "direnv was not installed."
end
