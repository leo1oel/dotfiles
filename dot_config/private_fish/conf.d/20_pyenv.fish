
if type -q pyenv
    if status is-interactive
        set -Ux PYENV_ROOT $HOME/.pyenv
        fish_add_path $PYENV_ROOT/bin
    end
    pyenv init - | source
    if type -q pyenv-virtualenv
        pyenv virtualenv-init - | source
    end
else
    echo "PyEnv was not installed."
end
