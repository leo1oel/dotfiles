# Set up Local Environment

fish_add_path $HOME/.local/bin

if test -n $DOTFILES_HOME
    if test -e $DOTFILES_HOME/local/bin
        fish_add_path $DOTFILES_HOME/local/bin
    end
    export DOTFILES_HOME
end
