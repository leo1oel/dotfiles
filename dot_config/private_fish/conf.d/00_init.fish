if test -z $DOTFILES_HOME
    if test -e $HOME/Dotfiles/init.sh
        set -Ux DOTFILES_HOME $HOME/Dotfiles
    else if test -e $HOME/.dotfiles/init.sh
        set -Ux DOTFILES_HOME $HOME/.dotfiles
    end
end

set -x LANG en_US.UTF-8
set -Ux EDITOR nvim

if test -e /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end
