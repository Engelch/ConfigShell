

function zsh.diverse.init() {
    debug4 zsh.diverse.init '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'

    #setopt autocd                   #  
    #setopt NO_CASE_GLOB
    setopt EXTENDED_HISTORY
    setopt SHARE_HISTORY            # share history across multiple zsh sessions
    setopt APPEND_HISTORY           # append to history

    SAVEHIST=5000
    HISTSIZE=2000
    HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history

    setopt INC_APPEND_HISTORY       # adds commands as they are typed, not at shell exit
    setopt HIST_EXPIRE_DUPS_FIRST   # expire duplicates first
    setopt HIST_IGNORE_DUPS         # do not store duplications
    setopt HIST_FIND_NO_DUPS        # ignore duplicates when searching
    setopt HIST_REDUCE_BLANKS       # removes blank lines from history

    #disable auto correct # correct_all will disable autocorrect for options only, not for commands themselves.
    # for all including commands use just correct
    unsetopt correct_all

    set +o nomatch    # get rid of the error messages if a shell globbing pattern cannot be resolved

    #### Reverting Shell Options for Defaults
    ## emulate -LR zsh                 # Useful in scripts

    autoload -Uz compinit && compinit   # load completions for curl,...
}

function zsh.diverse.del() {
    debug4 zsh.diverse.del '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
}

# EOF
