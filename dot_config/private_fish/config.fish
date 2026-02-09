if status is-interactive
    if test -f /opt/conda/etc/fish/conf.d/conda.fish
        source /opt/conda/etc/fish/conf.d/conda.fish
    end

    if command -q workmux
        workmux completions fish | source
    end
end
