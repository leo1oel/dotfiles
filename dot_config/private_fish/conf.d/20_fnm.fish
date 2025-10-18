# Add fnm to PATH if it exists
if test -d "$HOME/.local/share/fnm"
    fish_add_path "$HOME/.local/share/fnm"
end

# Initialize fnm if available
if type -q fnm
    fnm env | source
end
