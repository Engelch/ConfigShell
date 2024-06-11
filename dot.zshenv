
[ -z "$SHELL" ] && echo Setting SHELL... && export SHELL=/bin/zsh # fix for docker

# setopt noglob   # getting no error if a wildcard cannot be extended into strings
setopt ignoreeof                             # prevent ^d logout
setopt noclobber                             # overwrite protection, use >| to force

##############################################################################################

# SKELETON FUNCTIONS, considered R/O, v0.4.1

# so helps to write a message in reverse mode
function so()
# always show such a message.  If known terminal, print the message
# in reverse video mode. This is the other way, not using escape sequences
{
   [ "$1" != on -a "$1" != off ] && return 
    if [ "$TERM" = xterm -o "$TERM" = vt100 -o "$TERM" = xterm-256color  -o "$TERM" = screen ] ; then
      [ "$1" = on ] && tput smso 
      [ "$1" = off ] && tput rmso
    fi
}

# --- debug: Conditional debugging. All commands begin w/ debug.

function debugSet()             { DebugFlag=TRUE; return 0; }
[ -f "$HOME/.zsh.debug" ] && debugSet
function debugUnset()           { DebugFlag=; return 0; }
function debugExecIfDebug()     { [ "$DebugFlag" = TRUE ] && $*; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'$* 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' $* 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' $* 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:            ' $* 1>&2 ; return 0; }

function verbose()              { [ "$VerboseFlag" = TRUE ] && echo -n $* ; return 0; }
function verbosenl()            { [ "$VerboseFlag" = TRUE ] && echo $* ; return 0; }
function verboseSet()           { VerboseFlag=TRUE; return 0; }

# --- Colour lines. It requires either linux echo or zsh built-in echo

function colBold()      { printf '\e[1m'; return 0; }
function colNormal()    { printf "\e[0m"; return 0; }
function colBlink()     { printf "\e[5m"; return 0; }

# --- Exits

# function error()        { err 'ERROR:' $*; return 0; } # similar to err but with ERROR prefix and possibility to include 
# Write an error message to stderr. We cannot use err here as the spaces would be removed.
function error()        { so on; echo 'ERROR:'$* 1>&2;            so off ; return 0; }
function error4()       { so on; echo 'ERROR:    '$* 1>&2;        so off ; return 0; }
function error8()       { so on; echo 'ERROR:        '$* 1>&2;    so off ; return 0; }
function error12()      { so on; echo 'ERROR:            '$* 1>&2;so off ; return 0; }

function warning()      { so on; echo 'WARNING:'$* 1>&2;          so off; return 0; }


function errorExit()    { EXITCODE=$1 ; shift; error $* ; exit $EXITCODE; }
function exitIfErr()    { a="$1"; b="$2"; shift; shift; [ "$a" -ne 0 ] && errorExit $b App returned $b $*; }

function err()          { echo $* 1>&2; }                 # just write to stderr
function err4()         { echo '   ' $* 1>&2; }           # just write to stderr
function err8()         { echo '       ' $* 1>&2; }       # just write to stderr
function err12()        { echo '           ' $* 1>&2; }   # just write to stderr

# --- Existance checks
function exitIfBinariesNotFound()       { for file in $@; do [ $(command -v "$file") ] || errorExit 253 binary not found: $file; done }
function exitIfPlainFilesNotExisting()  { for file in $*; do [ ! -f $file ] && errorExit 254 'plain file not found:'$file 1>&2; done }
function exitIfFilesNotExisting()       { for file in $*; do [ ! -e $file ] && errorExit 255 'file not found:'$file 1>&2; done }
function exitIfDirsNotExisting()        { for dir in $*; do [ ! -d $dir ] && errorExit 252 "$APP:ERROR:directory not found:"$dir; done }

# --- Temporary file/directory  creation
# -- file creation -- TMP1=$(tempFile); TMP2=$(tempFile) ;;;; trap "rm -f $TMP1 $TMP2" EXIT
# -- directory creation -- TMPDIR=$(tempDir) ;;;;;  trap "rm -fr $TMPDIR;" EXIT
#
function tempFile()                     { mktemp ${TMPDIR:-/tmp/}$_app.XXXXXXXX; }
function tempDir()                      { mktemp -d "${TMPDIR:-/tmp/}$_app.YYYYYYYYY"; }
# realpath as shell, argument either supplied as stdin or as $1
# =========================================================================================

# debugSet

# user-specific pre/post/... configuration
function loadSource() {
   if [ -r "$HOME/.zshrc.$1" ] ; then debug loadSource .zshrc.$1 ; source "$HOME/.zshrc.$1" ; else 
      debug4 loadSource FILE NOT FOUND $HOME/.zshrc.$1 
   fi
}

# setupPath sets the path
function setupPath() {
    debug4 START setupPath
    [ $UID = 0 ] && debug4 root PATH initialisation &&  PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin
    [ $UID != 0 ] && debug4 normal user PATH init &&    PATH=./bin:/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin
    # add directories if existing for all platforms

    # 1
    debug8 "PREPENDING global PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.prepend.txt" ] && \
        while IFS= read -r line ; do
            line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs) # xargs for trimming outer spaces
            if [ -d "$line"  ] ; then debug12 "ok found path $line ::prepending" ; PATH="$line:$PATH"
            else debug12 "NOT ok path $line" ; fi
        done < "$PROFILES_CONFIG_DIR/Shell/path.prepend.txt"

    # 2
    debug8 "PREPENDING os-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).prepend.txt" ] && \
        while IFS= read -r line &>/dev/null; do
            line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
            if [ -d "$line" ] ; then debug12 "ok found path $line ::prepending" ; PATH="$line:$PATH"
            else debug12 "NOT ok path $line" ; fi
        done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).prepend.txt"

  # 3
    debug8 "PREPENDING architecture-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).prepend.txt" ] && \
        while IFS= read -r line &>/dev/null; do
            line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
            if [ -d "$line" ] ; then debug12 "ok found path $line ::prepending" ; PATH="$line:$PATH"
            else debug12 "NOT ok path $line" ; fi
        done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).prepend.txt"

    # 4
    debug8 "APPENDING global PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.append.txt" ] && \
        while IFS= read -r line; do
            line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
            if [ -d "$line" ] ; then debug12 "ok found path $line ::appending" ; PATH="$PATH:$line"
            else debug12 "NOT ok path $line" ; fi
        done < "$PROFILES_CONFIG_DIR/Shell/path.append.txt"

    # 5
    debug8 "APPENDING os-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).append.txt" ] && \
        while IFS= read -r line; do
            line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
            if [ -d "$line" ] ; then debug12 "ok found path $line ::appending" ; PATH="$PATH:$line" ;
            else debug12 "NOT ok path $line" ; fi
        done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).append.txt"

    # 6
    debug8 "APPENDING architecture-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).append.txt" ] && \
        while IFS= read -r line; do
            line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
            if [ -d "$line" ] ; then debug12 "ok found path $line ::apppending" ; PATH="$PATH:$line"
            else debug12 "NOT ok path $line" ; fi
        done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).append.txt"
    debug4 END setupPath
}

loadSource env
[ -z $NO_setupPath ] && setupPath

export ZSH_DISABLE_COMPFIX=true
export LESS='-iR'    # -i := searches are case insensitive; -R := Like -r, but only ANSI "color" escape sequences are output in "raw" form. The default is to display control characters using the caret notation.
export PAGER=less

export RSYNC_FLAGS="-rltDvu --modfiy-window=1"     # Windows FS updates file-times only every 2nd second
export RSYNC_SLINK_FLAGS="$RSYNCFLAGS --copy-links" # copy s-links as files
export RSYNC_LINK='--copy-links'

export VISUAL=vim
export EDITOR="$VISUAL"    # bsroot has no notion about VISUAL
export BLOCKSIZE=1K
export LC_ALL=en_US.UTF-8       # for ansible-vault which is required for git gee

debug END dot.zshenv
# EOF
