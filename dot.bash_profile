##### from skeleton

export DebugFlag=${DebugFlag:-FALSE}
export VerboseFlag=${VerboseFlasg:-FALSE}

# shall begin with .bash and end in .path
export PATHFILE="$HOME/.env.00profile.path"

######################################
# Skeleton functions, considered RO. v0.4.1

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

########### end of skeleton

# user-specific pre/post/... configuration
function loadSource() {
   if [ -r "$HOME/.bashrc.$1" ] ; then debug loadSource .bashrc.$1 ; source "$HOME/.bashrc.$1" ; else
      debug4 loadSource FILE NOT FOUND $HOME/.bashrc.$1
   fi
}

# sourcePaths reads a file with paths (1 per line) and adds it to the current PATH
function sourcePaths() {
    debug8 sourcePaths args: $*
    debug8 sourcePaths PATH is at start: $PATH
    [ -z "$*" ] && error4 argument to sourcePaths is empty && return

    NEWPATH=$(grep -hv '^#' $@ 2>&- | grep -v '^$' | while read line ; do
            [ -z "$line" ] && continue
            # debug8 adding sourced path $line
            echo -n :$line
        done
    )
    debug8 sourcePaths NEWPATH is now $NEWPATH
    NEWPATH=$(echo $NEWPATH | sed 's/^://')
    #debug8 NEWPATH $NEWPATH
    #PATH=$NEWPATH
    echo $NEWPATH
    unset NEWPATH
}

# setupPathInitial fills the path file (1st arg) which is not existing with the supplied path elements
# line by line
function setupPathInitial {
    debug8 in setupPathInitial writing file $1
    file="$1" ; shift
    for pathElem in $* ; do
        echo $pathElem >> $file
    done
}

# setupPath sets the path
function setupPath() {
    debug8 in setupPath ........
    # set up initial path
    if [ $UID = 0 ] ; then
        debug8 root PATH initialisation
        PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin
    else
        debug8 normal user PATH init, nothing
    fi
    # add directories if existing for all platforms
    for _POTENTIAL_DIR in \
        $HOME/go/bin $HOME/Library/Android/sdk/platform-tools /usr/local/share/dotnet /usr/local/go/bin \
        $HOME/.dotnet/tools $HOME/.rvm/bin /usr/local/google-cloud-sdk/ $HOME/google-cloud-sdk/ \
        $HOME/.pub-cache/bin /opt/flutter/bin $HOME/.linkerd2/bin $HOME/google-cloud-sdk/bin \
        /usr/local/google-cloud-sdk/bin \
        /opt/android-studio/bin
    do
        debug8 checking for dir $_POTENTIAL_DIR
        [ -d "$_POTENTIAL_DIR/." ] && debug8 found path element $_POTENTIAL_DIR && echo $_POTENTIAL_DIR >> "$PATHFILE"
    done
    debug8 setupPath PATHFILE is stage2: $([ -f $PATHFILE ] && cat $PATHFILE)
    unset _POTENTIAL_DIR
}

function delPath() {
    # deleting default cache path file build up by setupPath
    debug8 in delPath........
    [ -f "$PATHFILE" ] && debug12 PATHFILE $PATHFILE found, removing && /bin/rm -f $PATHFILE
}

# envVars set environment variables for all (sub-)shells
function envVars() {
    export SHELL=$(which bash)       # fix for docker
    export BASH_ENV=TRUE    # must be set before loading .bashrc files
    export LESS='-iR'       # -i := searches are case insensitive;
                            # -R := Like -r, but only ANSI "color" escape sequences are output in "raw" form.
                            # The default is to display control characters using the caret notation.
    export PAGER=less

    export RSYNC_FLAGS="-rltDvu --modfiy-window=1"      # Windows FS updates file-times only every 2nd second
    export RSYNC_SLINK_FLAGS="$RSYNCFLAGS --copy-links" # copy s-links as files
    export RSYNC_LINK='--copy-links'

    export VISUAL=vim
    export EDITOR=vim       # bsroot has no notion about VISUAL
    export BLOCKSIZE=1K

    export BASH_SILENCE_DEPRECATION_WARNING=1   # osx suppress bash warning

    export PROFILES_CONFIG_DIR=$(if [ $(command -v "realpath") ] ; then dirname $(realpath $HOME/.bashrc) ; else ls -l $HOME/.bashrc | awk '{ print $NF }' | xargs dirname ; fi ;)
    [ -z "$PROFILES_CONFIG_DIR" ] && error PROFILES_CONFIG_DIR not set
}

function main() {
    debug4 .bash_profile main..................

    # seem to be inherited to sub-shells
    set -o ignoreeof                             # prevent ^d logout
    set -o noclobber                             # overwrite protection, use >| to force

    # old call to ~/.bashrc.env
    PATH=/bin:/usr/bin:/usr/local/bin   # initial path for executing these scripts, to be fully set later by these scripts

    # PATH settings are environment variables. We do not want to do it for each individual sub-shell
    # PATHFILE must be set for these files (as done at BOF)
    [ $(echo $PATHFILE | wc -w ) -ne 1 ] && error something wrong about PATHFILE being $PATHFILE && return
    [ ! -f "$PATHFILE" ] && [ -z $NO_setupPath ] && setupPath # defined above in this file

    envVars     # load environment variables (above), required for PROFILES_CONFIG_DIR below, must be done after PATH setup

    # OS- and tools-based environment setup files
    export scriptcounter=0
    for file in $PROFILES_CONFIG_DIR/Shell/env.path.*.sh $PROFILES_CONFIG_DIR/Shell/env.os.$(uname).sh; do
        if [ -r $file ] ; then # required for the case if no such file exists
            scriptcounter=$(( scriptcounter + 1 ))
            debug $scriptcounter bash_profile sourcing $file............................
            source $file $HOME/.$(basename $file)
            $(basename $file .sh).init
        fi
    done

    NEWPATH=$(sourcePaths $HOME/.env.*.path)   # add the cached files with directories to the PATH env var
    PATH=.:$HOME/bin:$HOME/.local/bin:$PROFILES_CONFIG_DIR/bin:$PROFILES_CONFIG_DIR/bin_$(uname)-$(uname -m):/usr/local/bin:$NEWPATH:/bin:/usr/bin:/sbin:/usr/sbin

    [ -z "$NO_bashrc" -a -f ~/.bashrc ] && . ~/.bashrc # start all the normal files
}

debug START .................... dot.bash_profile
main $@
debug  STOP .................... dot.bash_profile

# EOF


test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

