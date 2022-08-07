function common.aliases.ls() {
    alias la="/bin/ls    -aCF       $LS_COLOUR"
    alias ll="/bin/ls    -lhF       $LS_COLOUR"
    alias lla="/bin/ls   -laF       $LS_COLOUR"
    alias lld="/bin/ls   -ldF       $LS_COLOUR"
    alias llad="/bin/ls  -ladF      $LS_COLOUR"
    alias ls="/bin/ls    -hCF       $LS_COLOUR"
}

function configshell-help() {
    echo ConfigShell is an OSS repository with mainly bash related aliases.
    echo It also supports zsh, tmux, git, k8s, and tls/ssh-related topics.
    echo
    echo Further, dedicated help can be found with the commands:
    echo
    echo git-help
    echo k8s-help
}

function common.aliases.init() {
    debug4 common.aliases.init '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    [ ! -z $NO_commonAliases ] && debug exiting common.aliases.sh && return

    alias ..='cd ..'
    alias .2='cd ../..'
    alias .3='cd ../../..'
    alias .4='cd ../../../..'
    alias .5='cd ../../../../..'
    alias .6='cd ../../../../../..'
    alias .7='cd ../../../../../../..'
    alias a=alias
    # delete current directory if empty or only OSX file .DS_Store is contained
    alias brmd='[ -f .DS_Store ] &&  /bin/rm -f .DS_Store ; cd .. ; rmdir "$OLDPWD"'
    alias cm=cmake
    alias cp='cp -i'
    alias disp0='export DISPLAY=:0'
    alias disp1='export DISPLAY=:1'
    alias e=egrep
    alias ei='egrep -i'
    alias eir='egrep -iR'
    alias enf='env | egrep -i '   # search the environment in case-insensitive mode
    alias er='egrep -R'
    alias fin='find . -name'      # search for a filename
    alias fini='find . -iname'    # search for a filename in case-insensitive mode
    alias h=history
    unalias hf 2>/dev/null
    function hf() {
        history | egrep -i "$*"
    }
    alias ipi='curl https://ipinfo.io'
    alias j=jobs
    alias l=less

    alias ln-s='ln -s'
    alias m=make
    alias mcd=mkcd
    function mkcd(){ mkdir -p $1 && cd $1; }
    alias mv='mv -i'
    alias po=popd
    alias pu='pushd .'
    alias rl="source ~/.$(basename $SHELL)rc"          # see also rlFull
    alias rm='rm -i'                    # life assurance
    alias rmtex='/bin/rm -f *.log *.aux *.dvi *.loc *.toc'   # remove temporary LaTeX/TeX files
    alias rm~='find . -name \*~ -print -exec /bin/rm {} \; ; find . -name \*.bak -print -exec /bin/rm {} \;'
    alias rmbak=rm~
    alias ssh-grep=ssf
    alias tm='tmux new -s '
    alias tw='tmux new-window -n'
    alias tn=tw
    alias tj='tmux join-pane -s'
    alias wh=which

    # all colour-changes to tmux can easily be found using the shell's built-in completion. Older, shorter completions are kept for a while
    alias tmux-prd='tmux select-pane -P "fg=white,bg=color052"' # colour values from https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
    alias tmux-prd2='tmux select-pane -P "fg=red,bg=color016"'  # colour values from https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
    alias prd2=tmux-prd2
    alias tmux-qul='tmux select-pane -P "fg=black,bg=color184"'
    alias qul=tmux-qul
    alias tmux-dvl='tmux select-pane -P "fg=white,bg=color017"'
    alias dvl=tmux-dvl
    alias tmux-loc='tmux select-pane -P "fg=white,bg=color237"'
    alias tmux-whbl='tmux select-pane -P "fg=white,bg=black"'
    alias tmux-blwh='tmux select-pane -P "fg=black,bg=white"'   # fg=169,bg=color233

    common.aliases.ls   # potentially reloading/re-evaluated again for colourised-ls from os.$(uname).ls
}

function common.aliases.del() {
    debug4 common.aliases.del '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
}

# EOF
