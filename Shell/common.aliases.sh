function common.aliases.ls() {
    alias la="/bin/ls    -aCF       $LS_COLOUR"
    alias ll="/bin/ls    -lhF       $LS_COLOUR"
    alias lla="/bin/ls   -laF       $LS_COLOUR"
    alias ls="/bin/ls    -hCF       $LS_COLOUR"
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
    alias hf='history | egrep -i '
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

    alias prd='tmux select-pane -P "fg=white,bg=color052"' # colour values from https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
    alias prdloc='tmux select-pane -P "fg=red,bg=color016"' # colour values from https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
    alias prd2=prdloc
    alias qul='tmux select-pane -P "fg=black,bg=color130"'
    alias dvl='tmux select-pane -P "fg=white,bg=color017"'
    alias loc='tmux select-pane -P "fg=white,bg=color237"'
    alias whbl='tmux select-pane -P "fg=white,bg=black"'
    alias blwh='tmux select-pane -P "fg=black,bg=white"'
    # fg=169,bg=color233
}

function common.aliases.del() {
    debug4 common.aliases.del '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
}

# EOF
