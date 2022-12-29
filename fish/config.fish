if status is-interactive
    # Commands to run in interactive sessions can go here
    abbr -a -g l less
    alias j=jobs
    abbr -a -g ln-s 'ln -s'
    alias cp='cp -i'
    alias rm='rm -i'
    alias mv='mv -i'
    function rmtex
        for file in  -f *.log *.aux *.dvi *.loc *.toc *~
            rm -fv $file
        end
    end
    abbr -a -g rm~ 'find . -name \*~ -print -exec /bin/rm -v {} \; ; find . -name \*.bak -print -exec /bin/rm -v {} \;'
    abbr -a -g  wh which

    alias la "ls -aCF $LS_COLOUR"
    alias ll "ls -lhF $LS_COLOUR"
    alias lla "ls   -laF       $LS_COLOUR"
    alias lld "ls   -ldF       $LS_COLOUR"
    alias llad "ls  -ladF      $LS_COLOUR"
    # alias ls "ls    -hCF       $LS_COLOUR"

    alias ..='cd ..'
    alias .2='cd ../..'
    alias .3='cd ../../..'
    alias .4='cd ../../../..'
    alias .5='cd ../../../../..'
    alias .6='cd ../../../../../..'
    alias .7='cd ../../../../../../..'
    alias brmd='[ -f .DS_Store ] &&  /bin/rm -f .DS_Store ; set -l a $PWD ; cd .. ; rmdir "$a"; set -e a'
    alias mcd=mkcd
    function mkcd
        mkdir -p $argv[1]
        cd $argv[1]
    end
    alias po=popd
    alias pu='pushd .'

    abbr -a -g cm cmake
    abbr -a -g m make

    alias disp0='export DISPLAY=:0'
    alias disp1='export DISPLAY=:1'

    abbr -a -g e "grep -E"
    abbr -a -g ei 'grep -Ei'
    abbr -a -g eir 'grep -EiR'
    abbr -a -g er 'grep -ER'
    abbr -a -g f 'grep -F'

    abbr -a -g enf 'env | grep -Ei'

    abbr -a -g fin 'find . -name'
    abbr -a -g fini 'find . -iname'

    alias h=history
    abbr -a -g hf 'history | grep -Ei'

    abbr -a -g ipi 'curl https://ipinfo.io'

    abbr -a -g giaa 'git add -A'
    abbr -a -g gibr 'git branch -avv'
    abbr -a -g gidi 'git diff'
    abbr -a -g gidic 'git diff --cached'
    abbr -a -g gife 'git fetch --all -p'
    abbr -a -g gilo 'git log --branches --remotes --tags --graph --oneline --decorate'
    abbr -a -g gist "git status -u --show-stash"
    abbr -a -g gipl 'git pull --all; git fetch --tags'
    abbr -a -g girm "git status | sed '1,/not staged/d' | grep deleted | awk '{print \$2}' | xargs git rm"
    function gipu
        git push --all $argv; and git push --tags $argv
    end
    function gipua
        for remoterepo in (grep '^\[remote' $(git rev-parse --show-toplevel)/.git/config | sed -e 's/.remote \"//' -e s'/..$//')
            git push --all $remoterepo ; git push --tags $argv
        end
    end
    function gicm
        if count $argv
            git commit -m "$argv"
        else
            git commit
        end
    end
    function gicma
        if count $argv
            git commit -a -m "$argv"
        else
            git commit -a
        end
    end

    alias ssh-grep=ssf

    abbr -a -g tm 'tmux new -s'
    abbr -a -g tw 'tmux new-window -n'
    alias tn=tw
    abbr -a -g tj 'tmux join-pane -s'
    abbr -a -g tmux-prd 'tmux select-pane -P "fg=white,bg=color052"'
    abbr -a -g prd 'tmux select-pane -P "fg=white,bg=color052"'
    abbr -a -g tmux-prd2 'tmux select-pane -P "fg=red,bg=color016"'
    abbr -a -g prd2 'tmux select-pane -P "fg=red,bg=color016"'
    abbr -a -g tmux-qul 'tmux select-pane -P "fg=black,bg=color179"'
    abbr -a -g qul 'tmux select-pane -P "fg=black,bg=color179"'
    abbr -a -g tmux-dvl 'tmux select-pane -P "fg=white,bg=color017"'
    abbr -a -g dvl 'tmux select-pane -P "fg=white,bg=color017"'
    abbr -a -g tmux-loc 'tmux select-pane -P "fg=white,bg=color237"'
    abbr -a -g loc 'tmux select-pane -P "fg=white,bg=color237"'
    abbr -a -g tmux-whbl 'tmux select-pane -P "fg=white,bg=black"'
    abbr -a -g whbl 'tmux select-pane -P "fg=white,bg=black"'
    abbr -a -g tmux-blwh 'tmux select-pane -P "fg=black,bg=white"'
    abbr -a -g blwh 'tmux select-pane -P "fg=black,bg=white"'

    set -g -x KUBECTL kubectl
    if which docker 2&>/dev/null
        set -g -x CONTAINER docker
        #echo set container $CONTAINER
    end
    if which podman 2&>/dev/null
        set -g -x CONTAINER podman
        #echo set container $CONTAINER
    end

    abbr -a -g dih      "$CONTAINER image history"
    abbr -a -g k        $KUBECTL
    abbr -a -g k8       $KUBECTL
    abbr -a -g k8s      $KUBECTL
    abbr -a -g k8af     "$KUBECTL apply -f"
    abbr -a -g k8df     "$KUBECTL delete -f"
    abbr -a -g k8c      "$KUBECTL config"
    abbr -a -g k8cg     "$KUBECTL config get-contexts"
    abbr -a -g k8cs     "$KUBECTL config set-context"
    abbr -a -g k8cu     "$KUBECTL config use-context"
    abbr -a -g k8cv     "$KUBECTL config view"
    abbr -a -g k8gd     "$KUBECTL get deploy -o wide"
    abbr -a -g k8gda    "$KUBECTL get deploy -o wide -A"
    abbr -a -g k8gdA    "$KUBECTL get deploy -o wide -A"
    abbr -a -g k8gn     "$KUBECTL get nodes -o wide"
    abbr -a -g k8gp     "$KUBECTL get pods -o wide"
    abbr -a -g k8gpa    "$KUBECTL get pods -A -o wide"
    abbr -a -g k8gpA    "$KUBECTL get pods -A -o wide"
    abbr -a -g k8gs     "$KUBECTL get services -o wide"
    abbr -a -g k8gsa    "$KUBECTL get services -o wide -A"
    abbr -a -g k8gsA    "$KUBECTL get services -o wide -A"
    abbr -a -g k8ns     "$KUBECTL get ns"
    abbr -a -g k8ga     "$KUBECTL get all"
    abbr -a -g k8gaa    "$KUBECTL get all -A"
    abbr -a -g k8gaA    "$KUBECTL get all -A"
    abbr -a -g k8gaw    "$KUBECTL get all -A -o wide"
    abbr -a -g k8gaaw   "$KUBECTL get all -A -o wide"
    abbr -a -g k8gaAw   "$KUBECTL get all -A -o wide"
    abbr -a -g k8ev     "$KUBECTL get events --sort-by=.metadata.creationTimestamp"
    abbr -a -g k8events "$KUBECTL get events --sort-by=.metadata.creationTimestamp"
    abbr -a -g k8eva    "$KUBECTL get events -A --sort-by=.metadata.creationTimestamp"
    abbr -a -g k8evA    "$KUBECTL get events -A --sort-by=.metadata.creationTimestamp"
end
