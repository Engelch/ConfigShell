#!/usr/bin/env bash
# vim:ts=2:sw=2
# shellcheck disable=SC2155 disable=SC2012 disable=SC2153

# Copyright © 2021 by Christian ENGEL (mailto:engel-ch@outlook.com)
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
#
# THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

export DebugFlag=${DebugFlag:-FALSE}

#########################################################################################
# SKELETON FUNCTIONS, considered R/O, v0.4.1

######################################
# Skeleton functions, considered RO. v0.5.0

# so helps to write a message in reverse mode
function so()
# always show such a message.  If known terminal, print the message
# in reverse video mode. This is the other way, not using escape sequences
{
   [ "$1" != on ] && [ "$1" != off ] && 1>&2 echo "so: unsupported option $1" && return
    if [ "$TERM" = xterm ] || [ "$TERM" = vt100 ] || [ "$TERM" = xterm-256color ] || [ "$TERM" = screen ] ; then
      [ "$1" = on ] && tput smso
      [ "$1" = off ] && tput rmso
    fi
}

# --- debug: Conditional debugging. All commands begin w/ debug.

function debugSet()             { DebugFlag="TRUE"; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debugExecIfDebug()     { [ "$DebugFlag" = TRUE ] && "$*"; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' "$*" 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:            ' "$*" 1>&2 ; return 0; }
function debug16()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:                ' "$*" 1>&2 ; return 0; }

# --- Colour lines. It requires either linux echo or zsh built-in echo

function colBold()      { printf '\e[1m'; return 0; }
function colNormal()    { printf "\e[0m"; return 0; }
function colBlink()     { printf "\e[5m"; return 0; }

# --- Exits

# function error()        { err 'ERROR:' $*; return 0; } # similar to err but with ERROR prefix and possibility to include
# Write an error message to stderr. We cannot use err here as the spaces would be removed.
function error()        { so on; echo 'ERROR:'"$*" 1>&2;            so off ; return 0; }
function error4()       { so on; echo 'ERROR:    '"$*" 1>&2;        so off ; return 0; }
function error8()       { so on; echo 'ERROR:        '"$*" 1>&2;    so off ; return 0; }
function error12()      { so on; echo 'ERROR:            '"$*" 1>&2;so off ; return 0; }

function warning()      { so on; echo 'WARNING:'"$*" 1>&2;          so off; return 0; }

function errorExit()    { EXITCODE=$1 ; shift; error "$*" ; exit "$EXITCODE"; }
function exitIfErr()    { a="$1"; b="$2"; shift; shift; "$a" || errorExit "$b" "App returned $b $*"; }

function err()          { echo "$*" 1>&2; }                 # just write to stderr
function err4()         { echo '   ' "$*" 1>&2; }           # just write to stderr
function err8()         { echo '       ' "$*" 1>&2; }       # just write to stderr
function err12()        { echo '           ' "$*" 1>&2; }   # just write to stderr

# --- Existance checks
function exitIfBinariesNotFound()       { for file in "$@"; do command -v "$file" &>/dev/null || errorExit 253 binary not found: "$file"; done }
function exitIfPlainFilesNotExisting()  { for file in "$@"; do [ ! -f "$file" ] && errorExit 254 'plain file not found:'"$file" 1>&2; done }
function exitIfFilesNotExisting()       { for file in "$@"; do [ ! -e "$file" ] && errorExit 255 'file not found:'"$file" 1>&2; done }
function exitIfDirsNotExisting()        { for dir in  "$@"; do [ ! -d "$dir"  ] && errorExit 252 "$APP:ERROR:directory not found:$dir"; done }

# --- Temporary file/directory  creation
# -- file creation -- TMP1=$(tempFile); TMP2=$(tempFile) ;;;; trap "rm -f $TMP1 $TMP2" EXIT
# -- directory creation -- TMPDIR=$(tempDir) ;;;;;  trap "rm -fr $TMPDIR;" EXIT
#
function tempFile()                     { mktemp ${TMPDIR:-/tmp/}$_app.XXXXXXXX; }
function tempDir()                      { mktemp -d "${TMPDIR:-/tmp/}$_app.YYYYYYYYY"; }
# realpath as shell, argument either supplied as stdin or as $1

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
   alias wh=which
   alias ssf=ssh-grep
   alias tm='tmux new -s'  # todo check tmux commnands, currently not working, and move tmux-qul,.. to scripts if possible
   alias tj='tmux join-pane -s'
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
export BASH_RC_VERSION="5.0.5"
debug BASH_RC_VERSION is $BASH_RC_VERSION
[ ! -z $BASH_MMONRC_VERSION ] && [ $BASH_MMONRC_VERSION != $BASH_RC_VERSION ] && echo New ConfigShell bash version $BASH_RC_VERSION. 1>&2
BASH_MMONRC_VERSION=$BASH_RC_VERSION
debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'

#################### EOF

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
