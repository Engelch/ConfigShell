
# install oh-my-zsh
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

fuunction loadOMZ() {
   # Path to your oh-my-zsh installation.
   export ZSH="$HOME/.oh-my-zsh"
   if [ ! -d "$ZSH/." -o -n "$ownPrompt" ] ; then
      echo non oh-my-zsh
      export ownPrompt=1
   else
      # Set name of the theme to load --- if set to "random", it will  load a random theme each time oh-my-zsh is loaded, in which case,
      # to know which specific one was loaded, run: echo $RANDOM_THEME  See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
      #ZSH_THEME="robbyrussell" # ZSH_THEME="candy" # ZSH_THEME="dallas" # ZSH_THEME="essembeh" # ZSH_THEME="jonathan" # ZSH_THEME="lukerandall"
      ZSH_THEME="agnoster"

      zstyle ':omz:update' mode reminder  # disabled | auto: just remind me to update when it's time
      zstyle ':omz:update' frequency 1 # Uncomment the following line to change how often to auto-update (in days).

      # DISABLE_MAGIC_FUNCTIONS="true" # Uncomment the following line if pasting URLs and other text is messed up.
      # DISABLE_LS_COLORS="true"      # Uncomment the following line to disable colors in ls.
      # DISABLE_AUTO_TITLE="true"      # Uncomment the following line to disable auto-setting terminal title.
      ENABLE_CORRECTION="false"      # Uncomment the following line to enable command auto-correction.

      # Uncomment the following line to display red dots whilst waiting for completion.
      # You can also set it to another string to have that shown instead of the default red dots.
      # e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
      # Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
      COMPLETION_WAITING_DOTS="true"

      # Uncomment the following line if you want to disable marking untracked files
      # under VCS as dirty. This makes repository status check for large repositories  much, much faster.
      # DISABLE_UNTRACKED_FILES_DIRTY="true"

      # Uncomment the following line if you want to change the command execution time  stamp shown in the history command output.
      # You can set one of the optional three formats:  "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
      # or set a custom format using the strftime function format specifications,  see 'man strftime' for details.  HIST_STAMPS="mm/dd/yyyy"
      HIST_STAMPS="yyyy-mm-dd"

      # Uncomment the following line to disable bi-weekly auto-update checks.
      DISABLE_AUTO_UPDATE="true"

      # ZSH_CUSTOM=/path/to/new-custom-folder      # Would you like to use another custom folder than $ZSH/custom?

      # Which plugins would you like to load?   Standard plugins can be found in $ZSH/plugins/
      # Custom plugins may be added to $ZSH_CUSTOM/plugins/  Example format: plugins=(rails git textmate ruby lighthouse)
      # Add wisely, as too many plugins slow down shell startup.
      plugins=(z sudo zsh-syntax-highlighting) # ruby rails git

      source $ZSH/oh-my-zsh.sh
      omzUpdateFlagFile="$HOME/.omzUpdate"
      if [[ $(find "$omzUpdateFlagFile" -mtime +1 -print) ]]; then
         debug "omz update flag file found, older than 1 day, tryting to update" 
         omz update
         touch "$omzUpdateFlagFile"
      elif [ ! -f  "$omzUpdateFlagFile" ] ; then
         debug "omz update flag file not found, creating it, and running omz update"
         omz update
         touch "$omzUpdateFlagFile"
      else
         debug "omz update flag file found, younger than 1 day, not updating"
      fi
      unset omzUpdateFlagFile
   fi
}

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
   source /opt/ConfigShell/dot.zshenv
   source /opt/ConfigShell/dot.zshrc
}

# toggle the ZSH prompt from an own prompt defined here and an OMZ prompt/theme
function togglePrompt {
   if [ -f "$ownPromptPath" ] ; then
      /bin/rm -f "$ownPromptPath"
   else
      touch "$ownPromptPath"
   fi
}

function main() {
   local files
   umask 022

   case $- in
      *i*) 
         NEWLINE=$'\n'
         ownPromptPath="$HOME/.ownPrompt"
         if [ -n "$INTELLIJ_ENVIRONMENT_READER" ]; then
            setupPath
            return
         fi
         [ "$ZSHENV_LOADED" != 1 ] && source /opt/ConfigShell/zsh/dot.zshenv && debug loading zshenv # after source .zshenv, debug is available
         debug START dot.zshrc interactive
         if [ -f "$ownPromptPath" ] ; then
               # gitContents is integrated here as it is required by setPrompt().
               # Helper for PS1, git bash prompt like, but much shorter and also working for darwin.
               function gitContents() {
                  if [[ $(git rev-parse --is-inside-work-tree 2>&1 | grep fatal | wc -l) -eq 0  ]] ; then
                           _gitBranch=$(git status -s -b | head -1 | sed 's/^##.//')
                           _gitStatus=$(git status -s -b | tail -n +2 | sed 's/^\(..\).*/\1/' | sort | uniq | tr "\n" " " | sed -e 's/ //g' -e 's/??/?/' -e 's/^[ ]*//')
                           echo $_gitStatus $_gitBranch
                  fi
               }
               setopt PROMPT_SUBST
               echo setting own prompt
               autoload -U colors
               autoload -Uz compinit   # required for compdef,..., otherwise loaded by omz
               compinit
               PROMPT='%(?..%F{red}%?$reset_color • )%F{green}%n@%m$reset_color • %* • %F{yellow}$(gitContents)$reset_color • %F{red}$AWS_PROFILE$reset_color • %{%F{cyan}%c%{$reset_color%}'$reset_color${NEWLINE}
               RPROMPT=
         else
            loadOMZ # deletes $PATH, so we set up path after this function   
         fi
         setupPath
         bindkey '^R' history-incremental-pattern-search-backward # history-incremental-search-backward
         bindkey -e # emacs mode
         # bindkey '^[[1;5C' emacs-forward-word
         # bindkey '^[^[[D' emacs-backward-word
         # realUserForHadm
         autoload -U +X bashcompinit && bashcompinit

         powertheme=/opt/homebrew/opt/powerlevel9k/powerlevel9k.zsh-theme
         [ -f "$powertheme" ] && source "$powertheme"

         loadAliases
         for file in $HOME/.sh.d/*.sh(N) $HOME/.zshrc.d/*.sh(N) ; do
            [ -f "$file" ] && zsh -f "$file"
            [ ! -f "$file" ] && echo found $file but it is not a plain file
         done
         for file in $HOME/.zshrc.d/*.rc(N) ; do
            [ -f "$file" ] && source "$file"
            [ ! -f "$file" ] && echo found $file but it is not a plain file
         done

         # terraform completion
         if [ -f /opt/homebrew/bin/terraform ] ; then
            complete -o nospace -C /opt/homebrew/bin/terraform terraform
         fi   
      
         debug end zshrc
         ;;
      *) #echo "This is a script";;
         ;;
   esac
}

main "$@"
return 0

# EOF
