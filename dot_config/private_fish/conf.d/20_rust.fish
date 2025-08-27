if test -d "$HOME/.rustup/bin"
    fish_add_path "$HOME/.rustup/bin"
end

if test -e "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end

