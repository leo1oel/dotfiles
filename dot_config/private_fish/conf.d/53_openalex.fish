# Export the OpenAlex API key for the `related-work-openalex` skill.
# The key is saved to a 0600 file by update-tools.sh (which prompts for it once);
# reading it from a file means non-interactive crewmate shells pick it up with no
# prompt. Get a free key at https://openalex.org/settings/api.
if not set -q OPENALEX_API_KEY; and test -r "$HOME/.config/openalex/api_key"
    set -gx OPENALEX_API_KEY (string trim <"$HOME/.config/openalex/api_key")
end
