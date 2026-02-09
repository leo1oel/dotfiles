set -l os (uname)

if test "$os" = Darwin
    alias nn="lsof -i | grep LISTEN"
    alias nna="lsof -i"
    alias lsusb="ioreg -p IOUSB"
    alias lsusb-v="system_profiler SPUSBDataType"
    alias firefox="/Applications/Firefox.app/Contents/MacOS/firefox"
    alias which="type -a"
else
    alias nn="sudo netstat -tnap"
    alias nna="sudo netstat -nap"
    alias nvitop="uvx nvitop"
end

alias du="du -h"
alias duu="du -d1 -h"

alias vi=nvim
alias nv=neovide
alias wm='workmux'

# Git aliases
alias gaa="git add --all"
alias gcmsg="git commit -m"
alias gp="git push"

if type -q yazi
    alias y=yazi
end
