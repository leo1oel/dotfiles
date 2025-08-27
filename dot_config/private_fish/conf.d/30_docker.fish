
if type -q docker
    alias dk="docker"
    alias dki="docker images"
    alias dkps="docker ps"
    alias dkpa="docker ps -a"
    alias dkr="docker run"
    alias dks="docker start"
    alias dkx="docker stop"
    alias dkrm="docker rm"
    alias dkrmi="docker rmi"
    alias dkcr="docker create"
    alias dkb="docker build"
    alias dkt="docker tag"
    alias dkpull="docker pull"
    alias dkpush="docker push"
    alias dkh="alias | grep '^dk'"
end
