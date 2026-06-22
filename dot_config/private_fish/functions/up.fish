function up --description 'Pull + apply dotfiles, and upgrade all CLI tools (via chezmoi)'
    # `chezmoi update` runs the run_after hook that upgrades Claude Code, Codex,
    # herdr, the skill-creator skill, uv tools, etc. So this one command does it all.
    chezmoi update $argv
end
