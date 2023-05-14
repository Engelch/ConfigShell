#!/usr/bin/env bash
# vim:ts=2:sw=2
# shellcheck disable=SC2155 disable=SC2012 disable=SC2153

# Copyright © 2023 by Christian ENGEL (mailto:engel-ch@outlook.com)
# License: BSD
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#    This product includes software developed by the <organization>.
# 4. Neither the name of the <organization> nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.

#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
#########################################################################################

# debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
# debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'

# =========================================================================================
# === normal use-case related functions ===================================================
# =========================================================================================

# user-specific pre/post/... configuration
function loadSource() {
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
   if [ -r "$HOME/.bashrc.$1" ] ; then debug8 "loadSource ~/.bashrc.$1" ; source "$HOME/.bashrc.$1" ; else
      debug8 "loadSource FILE NOT FOUND $HOME/.bashrc.$1"
   fi
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

# change default cd behaviour
function cd() {   # cd "$1" does not return to $HOME, if the 1st argument is given, but empty
   [ -z "$1" ] && builtin cd
   [ -n "$1" ] && builtin cd "$1"
   [ -f 00DIR.txt ] && cat 00DIR.txt
   [ -r 00DIR.sh ] && /usr/bin/env bash 00DIR.sh
   return 0
}

# setAliases sets the default aliases
function setAliases() {
   # ls aliases, all others as scripts in /opt/ConfigShell/bin
   alias ls="/bin/ls    -hCF       \$LS_COLOUR"
   alias ls-bw="export LS_COLOUR=--color=none"
   # cd aliases
   alias ..='cd ..'
   alias .2='cd ../..'
   alias .3='cd ../../..'
   alias .4='cd ../../../..'
   alias .5='cd ../../../../..'
   alias brmd='[ -f .DS_Store ] &&  /bin/rm -f .DS_Store ; cd .. ; rmdir "$OLDPWD"'
   # alias helpers
   alias a=alias
   alias af='alias | ei '
   # default commands
   alias cp='cp -i'
   alias e='grep -E'
   alias ei='grep -iE'
   alias eir='grep -iER'
   alias er='grep -ER'

   alias enf='env | grep -Ei '   # search the environment in case-insensitive mode
   alias fin='find . -name'      # search for a filename
   alias fini='find . -iname'    # search for a filename in case-insensitive mode

   alias h=history
   alias hf='history | grep -Ei'
   alias j=jobs
   alias l=less
   alias ln-s='ln -s'
   alias mcd=mkcd
   function mkcd(){ mkdir -p "$1" && cd "$1"; }
   alias mv='mv -i'
   alias po=popd
   alias pu='pushd .'
   alias rl="source ~/.bash_profile"
   alias rlDebug="debugSet; source ~/.bash_profile; debugUnset"
   alias rlFull=rlDebug            # backward compatibility
   alias rm='rm -i'           # life assurance
   alias rm~=rmbak    # stopped to be realised as a script because the script is deleted by rm~ :-)
   alias wh=which
   # X11 commands
   alias disp0='export DISPLAY=:0'
   alias disp1='export DISPLAY=:1'
   # sw development
   alias k=$KUBECTL
   alias k8=$KUBECTL
   alias k8s=$KUBECTL
}

# setHistFileUserShell: largely simplified history file management
function setHistFileUserShell() {
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
   HISTFILE=~/.bash_history
   HISTCONTROL=ignoredups:erasedups:ignorespace
   HISTSIZE=10000
   HISTFILESIZE=10000
   HISTTIMEFORMAT='%Y-%m-%d_%H%M%S: '
   PROMPT_COMMAND='history -a'
   shopt -s histappend   # When the shell exits, append to the history file instead of overwriting it
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

# gitContents is integrated here as it is required by setPrompt().
# Helper for PS1, git bash prompt like, but much shorter and also working for darwin.
function gitContents() {
    if [[ $(git rev-parse --is-inside-work-tree 2>&1 | grep fatal | wc -l) -eq 0  ]] ; then
            _gitBranch=$(git status -s -b | head -1 | sed 's/^##.//')
            _gitStatus=$(git status -s -b | tail -n +2 | sed 's/^\(..\).*/\1/' | sort | uniq | tr "\n" " " | sed -e 's/ //g' -e 's/??/?/' -e 's/^[ ]*//')
            echo $_gitStatus $_gitBranch
    fi
}

# setPrompt
function setPrompt() {
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
   if [ $(id -u) -eq 0 ] ; then
      debug8 bash ROOT shell
      PATH=/sbin:/bin:/usr/sbin:/usr/bin:"$PATH" # security: no enhanced PATHs first
      PS1='[$?] \033[0;31m\t | \u@\h | $(pwd) \033[0m##########################\n'
   else
      debug8 bash non-root shell
      [ $(which watson | wc -l) -eq 0 ] && debug12 watson not found && alias watson='echo -- > /dev/null'
      PS1='[$?] \033[34m\t\033[0m|\033[32m\u@\h\033[0m|\033[34m$(watson status)\033[0m|\033[0;31m$(gitContents)\033[0m|$AWS_PROFILE|\033[0;33m\w\e[0m\n'
   fi
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

# todo check w/ Lx system
# hadmRealUserDetermination determines the real user if logging is as hadm
# The function is currently designed to work only on systems with systemd
function hadmRealUserDetermination() {
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
   if [[ $(id -un) == "hadm" ]]  && command -v journalctl &>/dev/null ; then
      debug8 user hadm and journalctl existing
      [ -z "$HADM_LAST_LOGIN_FINGERPRINT" ] && unset HADM_LAST_LOGIN_FINGERPRINT
      export HADM_LAST_LOGIN_FINGERPRINT=${HADM_LAST_LOGIN_FINGERPRINT:-$(sudo journalctl -r -u ssh -g 'Accepted publickey' -n 1 -q 2>&1 | awk '{ print $NF }')}
      debug8 HADM_LAST_LOGIN_FINGERPRINT "$HADM_LAST_LOGIN_FINGERPRINT"
      debug8 "SSH_CLIENT $SSH_CLIENT"

      if [ "$SSH_CLIENT" != "" ] && [ ! -z "$HADM_LAST_LOGIN_FINGERPRINT" ] ; then
         for file in ~/.ssh/*.pub
         do
            if [ $(ssh-keygen -lf $file | grep $HADM_LAST_LOGIN_FINGERPRINT | wc -l) -eq 1 ] ; then
               export HADM_LAST_LOGIN_USER=$(basename $file .pub)
               logger "You are user $HADM_LAST_LOGIN_USER logging in as hadm. Welcome."
               echo You are user "$HADM_LAST_LOGIN_USER" logging in as hadm. Welcome.
               break
            fi
         done
      else
         debug8 "SSH_CLIENT or HADM_LAST_LOGIN_FINGERPRINT not set"
      fi
   else
      debug8 "User not hadm $(id -un) or journalctl not existing"
   fi
   debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

############################################################################
# main
############################################################################

function main() {
   debug4 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
   umask 0022

   case $- in
      *i*) #  "This shell is interactive"
         # source .bash_profile if it was not done before
         # shellcheck source=/dev/null
         [ -z "$BASH_ENV" ] && [ -r ~/.bash_profile ] && source ~/.bash_profile && return
         loadSource pre
         export USER=${USER:-root} # fix for docker
         export SHELL=${SHELL:-$(ps a | grep $$ | sed -n "/^ *$$/p" | awk '{ print $NF }')} # fix for docker
         setHistFileUserShell                      # history file permission, ownership, settings
         setPrompt
         $(which aws_completer &>/dev/null) && debug4 aws completion helper found && complete -C "$(which aws_completer)" aws
         setAliases
         hadmRealUserDetermination

         # changed to common2.* and bash2.* files
         for file in $PROFILES_CONFIG_DIR/Shell/common.*.rc $PROFILES_CONFIG_DIR/Shell/bash.*.rc $PROFILES_CONFIG_DIR/Shell/os."$(uname)".rc; do
            if [ -f "$file"  ] && [ -r "$file" ] ; then
               # shellcheck source=/dev/null
               source "$file" # removing constructor style: $(basename $file .sh).init # call the file-local initialiser
            fi
         done

         # load ssh and rsync completion, the completion list can be created with ssh-createCompletionList
         local sshCompletionList="$HOME/.ssh/completion.lst"
         [ -f $sshCompletionList ] && \
            complete -W "$(cat $sshCompletionList)" -- ssh && \
            complete -f -d -W "$(cat $sshCompletionList)" -- rsync

         loadSource post
         for file in $HOME/.bashrc.d/*.rc ; do
            [ "$file" = "$HOME/.bashrc.d/"'*.rc' ] && continue # in case that no file is found
            [ -r "$file" ] && debug4 sourcing "$file" && source "$file"
            [ -r "$file" ] || err could not read "$file"
         done
         for file in $HOME/.bashrc.d/*.sh ; do
            [ "$file" = "$HOME/.bashrc.d/"'*.sh' ] && continue # in case that no file is found
            [ -r "$file" ] && debug4 executing "$file" && bash "$file"
            [ -r "$file" ] || err could not read "$file"
         done
         ;;
      *) #echo "This is a script";;
         debug non-interactive shell
         ;;
   esac
   debug4 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
main "$@"
export BASH_RC_VERSION="5.0.7"
debug BASH_RC_VERSION is $BASH_RC_VERSION
[ ! -z $BASH_MMONRC_VERSION ] && [ $BASH_MMONRC_VERSION != $BASH_RC_VERSION ] && echo New ConfigShell bash version $BASH_RC_VERSION. 1>&2
BASH_MMONRC_VERSION=$BASH_RC_VERSION
debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'

export SDKMAN_DIR="$HOME/.sdkman" #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

#################### EOF
