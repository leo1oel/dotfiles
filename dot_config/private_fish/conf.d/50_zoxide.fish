
if type -q zoxide
    # Use --no-cmd to avoid errors when Fish is installed in non-standard location
    # This prevents zoxide from trying to override the cd command
    # Use 'z' command instead of 'cd' for zoxide navigation
    zoxide init fish --no-cmd | source

    # Optional: Create a simple 'z' alias if you want
    # You can still use 'cd' normally, and 'z' for smart directory jumping
else
    echo "zoxide was not installed."
end
