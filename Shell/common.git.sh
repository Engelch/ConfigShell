# ---- GIT  -----------------------------------------------------------------------

# gitContents: helper for PS1: git bash prompt like, but much shorter and also working for darwin.
function gitContents() {
    if [[ $(git rev-parse --is-inside-work-tree 2>&1 | grep fatal | wc -l) -eq 0  ]] ; then
            _gitBranch=$(git status -s -b | head -1 | sed 's/^##.//')
            _gitStatus=$(git status -s -b | tail -n +2 | sed 's/^\(..\).*/\1/' | sort | uniq | tr "\n" " " | sed -e 's/ //g' -e 's/??/?/' -e 's/^[ ]*//')
            echo $_gitStatus $_gitBranch
    fi
}

# help to show all git helpers
# function gihelp() {
#     cat  $PROFILES_CONFIG_DIR/Shell/common.git.sh \
#     | grep -v '#####' \
#     | grep '##' \
#     | sed 's/^[[:space:]]*##$//' \
#     | sed 's/^[[:space:]]*## /    /' \
#     | sed 's/^[[:space:]]*### /    ## /' \
#     | sed 's/^[[:space:]]*#### /    # /' \
#     | grep -v _gitBranch= \
#     | sed -E 's/^[[:space:]]*//' \
#     | egrep -Ev '^\|'
# }

# alias git-help=gihelp ##

function lower() {
    echo $* | tr "[:upper:]" "[:lower:]"
}

function upper() {
    echo $* | tr "[:lower:]" "[:upper:]"
}

function common.git.init() {
    debug4 common.git.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ ! -z $NO_gitCommon ] && debug exiting common.git.sh && return
    debug8 setting up git...
    # setupGit
    if [[ "$SHELL" =~ bash && $(lower $NO_gitCompletion) != true ]] ; then
        debug8 loading bash git completion
        [ ! -r "$PROFILES_CONFIG_DIR/git-completion.bash" ] && 1>&2 echo ERROR: Cannot find completion file && return 1
        . "$PROFILES_CONFIG_DIR/git-completion.bash"
        gitCompletionLoaded=true
    fi
    return 0
}

function common.git.del() {
    debug4 common.git.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if [ ! -z "$gitCompletionLoaded" ] ; then
        debug8 removing completions for git, gitk
        complete -r git
        complete -r gitk
        unset gitCompletionLoaded
    fi
}

# EOF
