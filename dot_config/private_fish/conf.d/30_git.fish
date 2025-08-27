
if type -q git
    alias g="git"
    alias gst="git status"
    alias gpoh="git push origin HEAD"
    alias ga.="git add ."
    alias gcm="git commit -m"
    alias gfop="git fetch origin -p"
    alias gdf="git diff"
    alias gdfs="git diff --staged"
    alias grbm="git rebase origin/master"
    alias gmomm="git merge origin/master -m 'Merge remote-tracking branch origin/master'"
else
    echo "GIT was not installed."
end

if type -q pre-commit
    alias pcr="pre-commit run -a"
end
