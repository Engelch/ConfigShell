#!/usr/bin/env bash
# shellcheck disable=SC2155 disable=SC2012 disable=SC2153

######################################
# Skeleton functions, considered RO. v1.0.0

# so helps to write a message in reverse mode
function so()
# always show such a message.  If known terminal, print the message
# in reverse video mode. This is the other way, not using escape sequences
{
   [ "$1" != on ] && [ "$1" != off ] && 1>&2 echo "so: unsupported option $1" && return
    if [ "$TERM" = "xterm" ] || [ "$TERM" = "vt100" ] || [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "screen" ] ; then
      [ "$1" = "on" ] && tput smso
      [ "$1" = "off" ] && tput rmso
    fi
}

# --- debug: Conditional debugging. All commands begin w/ debug.
export DebugFlag=${DebugFlag:-FALSE}
function debugSet()             { DebugFlag="TRUE"; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debugExecIfDebug()     { [ "$DebugFlag" = TRUE ] && "$*"; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' "$*" 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:            ' "$*" 1>&2 ; return 0; }

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

########### end of skeleton

function setupPathsFromFiles() {
   debug12 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'

   # 1
    debug12 "PREPENDING global PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.prepend.txt" ] && \
       while IFS= read -r line ; do
         line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME,")
         if [ -d "$line"  ] ; then debug12 "Found path $line ::prepending" ; PATH="$line:$PATH"
         else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.prepend.txt"

    # 2
    debug12 "PREPENDING os-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).prepend.txt" ] && \
       while IFS= read -r line &>/dev/null; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME,")
          if [ -d "$line" ] ; then debug12 "Found path $line ::prepending" ; PATH="$line:$PATH"
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).prepend.txt"

    # 3
    debug12 "PREPENDING architecture-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).prepend.txt" ] && \
       while IFS= read -r line &>/dev/null; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME,")
          if [ -d "$line" ] ; then debug12 "Found path $line ::prepending" ; PATH="$line:$PATH"
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).prepend.txt"

    # 4
    debug12 "APPENDING global PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.append.txt" ] && \
       while IFS= read -r line; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME,") # trim outer space
          if [ -d "$line" ] ; then debug12 "Found path $line ::appending" ; PATH="$PATH:$line"
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.append.txt"

    # 5
    debug12 "APPENDING os-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).append.txt" ] && \
       while IFS= read -r line; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME,")
          if [ -d "$line" ] ; then debug12 "Found path $line ::appending" ; PATH="$PATH:$line" ;
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).append.txt"

    # 6
    debug12 "APPENDING architecture-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).append.txt" ] && \
       while IFS= read -r line; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME,")
          if [ -d "$line" ] ; then debug12 "Found path $line ::apppending" ; PATH="$PATH:$line"
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).append.txt"

    debug12 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}



# setupPath sets the path
function setupPath() {
    debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
    local _POTENTIAL_DIR
    # set up initial path
    PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin
    if [ "$UID" = 0 ] ; then
        debug8 root PATH initialisation
        PATH=/sbin:/usr/sbin:/bin:/usr/bin
    fi
    # add directories if existing for all platforms
    setupPathsFromFiles
    debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

# envVars set environment variables for all (sub-)shells
function envVars() {
    debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
    export SHELL=$(which bash || errorExit 1 "bash could not be found")       # fix for docker
    export BASH_ENV=TRUE    # tells bashrc that bash_profile was loaded
    export LESS='-iR'       # -i := searches are case insensitive;
                            # -R := Like -r, but only ANSI "color" escape sequences are output in "raw" form.
                            # The default is to display control characters using the caret notation.
    export PAGER=less

    export RSYNC_FLAGS="-rltDvu --modfiy-window=1"      # Windows FS updates file-times only every 2nd second
    export RSYNC_SLINK_FLAGS="$RSYNCFLAGS --copy-links" # copy s-links as files
    export RSYNC_LINK='--copy-links'

    export VISUAL=vim
    export EDITOR="$VISUAL"       # bsroot has no notion about VISUAL
    export BLOCKSIZE=1K

    export KUBECTL=kubectl
    if which docker 2&>/dev/null ; then
        export CONTAINER=docker
        debug8 CONTAINER $CONTAINER
    fi
    if which podman 2&>/dev/null ; then
        export CONTAINER=podman
        debug8 CONTAINER $CONTAINER
    fi

    export BASH_SILENCE_DEPRECATION_WARNING=1   # OSX suppress bash warning
    export LS_COLOUR='-G'
    export LSCOLORS=Exfxcxdxbxegedabagacad # change directory colour 1st letter; see man ls(1)

    export PROFILES_CONFIG_DIR=$(ls -l "$HOME/.bashrc" | awk '{ print $NF }' | xargs dirname)
    [ -z "$PROFILES_CONFIG_DIR" ] && error PROFILES_CONFIG_DIR not set
    debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

function main() {
    debug4 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'

    # seem to be inherited to sub-shells
    set -o ignoreeof                             # prevent ^d logout
    set -o noclobber                             # overwrite protection, use >| to force

    envVars     # load environment variables (above), required for PROFILES_CONFIG_DIR below, must be done after PATH setup
    setupPath

    # shellcheck source=/dev/null
    [ -z "$NO_bashrc" ] && [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"    # start all the normal files

    # iterm @OSX
    # shellcheck source=/dev/null
    [ -r "$HOME/.iterm2_shell_integration.bash" ] && [ "$(uname)" = "Darwin" ] && source "$HOME/.iterm2_shell_integration.bash"
    debug4 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
main "$@"
debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'


# EOF
