
function loadAliases() {
   debug4 loading aliases
   alias .2='cd ../..'
   alias .3='cd ../../..'
   alias .4='cd ../../../..'
   alias .5='cd ../../../../..'

   alias a=alias
   alias af='alias | ei'
   alias brmd='[ -f .DS_Store ] &&  /bin/rm -f .DS_Store ; cd .. ; rmdir "$OLDPWD"'
   alias cd..='cd ..'
   alias cp='cp -i'
   # X11 commands
   alias disp0='export DISPLAY=:0'
   alias disp1='export DISPLAY=:1'
   alias e='grep -E'
   alias ei='grep -iE'
   alias eir='grep -iER'
   alias er='grep -ER'
   alias f=fuck
   alias g=git
   alias h=history
   alias hf='history | grep -Ei'
   alias j=jobs
   alias k=$KUBECTL
   alias k8=$KUBECTL
   alias k8s=$KUBECTL
   alias l=less
   alias ls='ls -FG'
   alias mcd=mkcd
   function mkcd(){ mkdir -p "$1" && cd "$1"; }
   alias mv='mv -i'
   alias o=open
   alias po=popd
   alias pu=pushd
   alias rm='rm -i'
   alias rm~='rmbak'
   alias wh=which
   # suffix aliases
   alias -s c="$VISUAL"
   alias -s rb="$VISUAL"
   alias -s php="$VISUAL"
   alias -s go="$VISUAL"
   alias -s rs="$VISUAL"
   debug4 end loading aliases
}


function rl() {
   for file in /opt/ConfigShell/zsh/dot.zshenv /opt/ConfigShell/zsh/dot.zshrc ; do
      [ ! -r "$file" ] && echo file not found "$file"
      [   -r "$file" ] && source "$file"
   done
}

function loadSshCompletionSpeedUp() {
   typeset -rl _completion=~/.ssh/completion.lst
   [ -d ~/.ssh ] && [ ! -f $_completion ] && { 1>&2 echo SSH completion list not found, please consider running ssh-createCompletionList. ; return ; }
   host_list=($(cat $_completion))
   zstyle ':completion:*:(ssh|scp|sftp|rsync):*' hosts $host_list
}

function chpwd () {
   [ -f 00DIR.txt ] && cat 00DIR.txt
   [ -r 00DIR.sh ] && /usr/bin/env zsh 00DIR.sh
}

function main() {
   local files
   umask 022

   case $- in
      *i*) 
         NEWLINE=$'\n'
         if [ -n "$INTELLIJ_ENVIRONMENT_READER" ]; then
            setupPath
            return
         fi
         [ "$ZSHENV_LOADED" != 1 ] && source /opt/ConfigShell/zsh/dot.zshenv && debug loading zshenv # after source .zshenv, debug is available
         debug START dot.zshrc interactive
         # gitContents is integrated here as it is required by setPrompt().
         # Helper for PS1, git bash prompt like, but much shorter and also working for darwin.
         function gitContents() {
            if [[ $(git rev-parse --is-inside-work-tree 2>&1 | grep fatal | wc -l) -eq 0  ]] ; then
                _gitBranch=$(git status -s -b | head -1 | sed 's/^##.//')
                _gitStatus=$(git status -s -b | tail -n +2 | sed 's/^\(..\).*/\1/' | sort | uniq | tr "\n" " " | sed -e 's/ //g' -e 's/??/?/' -e 's/^[ ]*//')
                echo $_gitStatus $_gitBranch
            fi
         }
         set autocd # enter dir with just specifying it, no cd required
         setopt PROMPT_SUBST
         autoload -Uz compinit   # required for compdef,..., otherwise loaded by omz
         compinit
         PROMPT='%(?.√.%K{red}%?%k) %n@%m [$AWS_PROFILE] ($(eval gitContents)) %~ %# ${NEWLINE}'
         unset RPROMPT
         setupPath
         bindkey '^R' history-incremental-pattern-search-backward # history-incremental-search-backward
         bindkey -e # emacs mode
         loadSshCompletionSpeedUp
         autoload -U +X bashcompinit && bashcompinit
         zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'  # allow case-insensitive completion
         if [ -e  ~/.docker/completions ]; then
            debug docker completions found, evaluating
            tmp=~/.docker/completions  # required,as ~ is expanded before it it added to the array; double quoting also does not work
            if (( $fpath[(Ie)$tmp] )); then
               debug4 docker completions already found, not adding it again
            else
               fpath=($tmp $fpath)
               debug4 docker completions added
            fi
            unset tmp
         fi
         autoload -Uz compinit && compinit

         loadAliases
         for file in $HOME/.sh.d/*.sh(N) $HOME/.zshrc.d/*.sh(N) ; do
            [ -f "$file" ] && zsh -f "$file"
            [ ! -f "$file" ] && echo found $file but it is not a plain file
         done
         for file in $HOME/.zshrc.d/*.rc(N) ; do
            [ -f "$file" ] && source "$file"
            [ ! -f "$file" ] && echo found $file but it is not a plain file
         done

         which thefuck &>/dev/null && debug loading thefuck && eval $(thefuck --alias)
         which atuin &>/dev/null && debug loading atuin && source /opt/ConfigShell/zsh/atuin.rc &&
            atuin import auto &&
            atuin sync
      
         debug end zshrc interactive
         ;;
      *) #echo "This is a script";;
         ;;
   esac
}

main "$@"
return 0

# EOF
