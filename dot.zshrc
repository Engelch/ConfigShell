
# install oh-my-zsh
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

fuunction interactiveShell() {
   # Path to your oh-my-zsh installation.
   export ZSH="$HOME/.oh-my-zsh"
   if [ ! -d "$ZSH/." -o -n "$ownPrompt" ] ; then
      echo non oh-my-zsh
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

      ENABLE_CORRECTION="true"      # Uncomment the following line to enable command auto-correction.

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

      # ZSH_CUSTOM=/path/to/new-custom-folder      # Would you like to use another custom folder than $ZSH/custom?

      # Which plugins would you like to load?   Standard plugins can be found in $ZSH/plugins/
      # Custom plugins may be added to $ZSH_CUSTOM/plugins/  Example format: plugins=(rails git textmate ruby lighthouse)
      # Add wisely, as too many plugins slow down shell startup.
      plugins=(rails git ruby)

      source $ZSH/oh-my-zsh.sh
   fi
}


function main() {
   local files
   umask 022 # umask 022 for group work, removed again because this does not work properly for SSH cfg files...

   export PROFILES_CONFIG_DIR=$(dirname "$(readlink -f ~/.zshrc)")
   debug PROFILES_CONFIG_DIR: $PROFILES_CONFIG_DIR

   loadSource pre

    case $- in
        *i*) #  "This shell is interactive"
            interactiveShell
            NEWLINE=$'\n'
            if [ -n "$ownPrompt" ] ; then
                setopt PROMPT_SUBST
                echo setting own prompt
                autoload -U colors
                PROMPT='%(?..%F{red}%?$reset_color • )%F{green}%n@%m$reset_color • %* • %F{yellow}$(gitContents)$reset_color • %F{red}$AWS_PROFILE$reset_color • %{%F{cyan}%c%{$reset_color%}'$reset_color${NEWLINE}
                RPROMPT=
            fi
            bindkey '^R' history-incremental-pattern-search-backward # history-incremental-search-backward
            bindkey -e # emacs mode
            # bindkey '^[[1;5C' emacs-forward-word
            # bindkey '^[^[[D' emacs-backward-word
         # realUserForHadm
            autoload -U +X bashcompinit && bashcompinit
# complete -o nospace -C /opt/homebrew/bin/terraform terraform

            #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
            export SDKMAN_DIR="$HOME/.sdkman"
            [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

#            complete -o nospace -C /usr/bin/terraform terraform
            powertheme=/opt/homebrew/opt/powerlevel9k/powerlevel9k.zsh-theme
            [ -f "$powertheme" ] && source "$powertheme"

            [ -z "$NO_loadPost" ] && loadSource post
            ;;
        *) #echo "This is a script";;
            ;;
    esac
}

main $@
return 0

# EOF

