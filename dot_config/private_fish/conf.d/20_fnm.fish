if type -q fnm
    fnm env | source
else
    echo "fnm (Fast Node Manager) was not installed"
end
