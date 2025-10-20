#!/bin/bash

# Exit if get-secret.sh is already in PATH
type get-secret.sh >/dev/null 2>&1 && exit 0

# Ensure ~/.local/bin exists
mkdir -p "${HOME}/.local/bin"

# Copy get-secret.sh to ~/.local/bin
if [ -f "${HOME}/.local/share/chezmoi/private_dot_local/bin/executable_get-secret.sh" ]; then
    cp "${HOME}/.local/share/chezmoi/private_dot_local/bin/executable_get-secret.sh" "${HOME}/.local/bin/get-secret.sh"
    chmod +x "${HOME}/.local/bin/get-secret.sh"

    # Add ~/.local/bin to PATH for current session
    export PATH="${HOME}/.local/bin:${PATH}"

    echo "✅ get-secret.sh installed to ~/.local/bin"
else
    echo "⚠️  Could not find executable_get-secret.sh in chezmoi source"
    exit 1
fi
