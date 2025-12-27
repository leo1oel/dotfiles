##################
# Helix Editor
##################

if type -q helix
    if not type -q hx
        alias hx=helix
    end

    # Prefer Helix over vi
    alias vi=helix
end
