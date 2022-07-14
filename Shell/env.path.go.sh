function setupGoPath() {
    # go sdk setup, NO_GoSDK might require a second load as loadSource pre is not executed before
    if [ -z "$NO_GoSDK" -a -d "$HOME/sdk" ] ; then
        debug8 check for go SDK
        local -r _go=$(/bin/ls -1 $HOME/sdk/ | tail -n 1 | sed 's,/$,,')
        echo $HOME/sdk/$_go/bin >| $GO_PATH_CACHE_FILE
        export GOROOT=$HOME/sdk/$_go/
        debug8 Setting PATH for local go environment and GOROOT to $GOROOT
    fi
    [ -z "$NO_GoSDK" -a -d "$HOME/.go/bin" ] && \
        echo $HOME/.go/bin >| $GO_PATH_CACHE_FILE && \
        export GOROOT=$HOME/.go && \
        debug8 Setting PATH for local go environment and GOROOT to $GOROOT
}

GO_PATH_CACHE_FILE=$HOME/.env.go.path

function env.path.go.init() {
    debug4 env.path.go.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if [ -f "GO_PATH_CACHE_FILE" ] ; then
        debug8 cached go path existing
        export GOROOT=$(basename $(cat "$GO_PATH_CACHE_FILE") /bin)
    else
        setupGoPath
    fi
}


function env.path.go.del() {
    debug4 env.path.go.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ -f "$GO_PATH_CACHE_FILE" ] && \
        debug8 GO_PATH_CACHE_FILE $GO_PATH_CACHE_FILE found, removing && \
        /bin/rm $GO_PATH_CACHE_FILE && \
        return
    debug8 GO_PATH_CACHE_FILE NOT FOUND
}

# EOF

