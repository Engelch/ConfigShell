##############################################################################################
# debugSet

# helper for setupPath
function loadPath() {
    debug4 START loadPath "$@"
    [ ! -r "$2" ] && error12 "loadPath: file not found: $2" && return
    [   -r "$2" ] && while IFS= read -r line; do
        line=$(echo "$line" | grep -v '^#' | grep -v '^$' | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
        if [ -d "$line" ] ; then 
            debug8 "ok found directory $line" ; 
            case "$1" in
                prepend) PATH="$line:$PATH" ;;
                append)  PATH="$PATH:$line" ;;
                *) error8 "loadPath: unknown mode $1 for path $2" && return ;;
            esac
        else debug8 "not found: directory $line" ; fi
    done < "$2"
    debug4 END loadPath
}

# setupPath sets the path
function setupPath() {
    debug START setupPath
    [ $UID = 0 ] && debug4 root PATH initialisation &&  PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin
    [ $UID != 0 ] && debug4 normal user PATH init &&    PATH=./bin:/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin
    # add directories if existing for all platforms

    # 1
    loadPath prepend "$PROFILES_CONFIG_DIR/ShellPaths/path.prepend.txt"
    # 2
    loadPath prepend "$PROFILES_CONFIG_DIR/ShellPaths/path.$(uname).prepend.txt"
    # 3
    loadPath prepend "$PROFILES_CONFIG_DIR/ShellPaths/path.$(uname).$(uname -m).prepend.txt"
    # 4
    loadPath append "$PROFILES_CONFIG_DIR/ShellPaths/path.append.txt"
    # 5
    loadPath append "$PROFILES_CONFIG_DIR/ShellPaths/path.$(uname).append.txt"
    # 6
    loadPath append "$PROFILES_CONFIG_DIR/ShellPaths/path.$(uname).$(uname -m).append.txt"
    debug END setupPath
}

function loadLibs() {
    bashLib="$PROFILES_CONFIG_DIR/lib/bashlib.sh"
    [ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && export errorSet=1
    source "$bashLib"
    unset bashLib
}

# =========================================================================================
# start
# =========================================================================================

[ -z "$SHELL" ] && echo Setting SHELL... && export SHELL=/bin/zsh # fix for docker

# setopt noglob   # getting no error if a wildcard cannot be extended into strings
setopt ignoreeof                             # prevent ^d logout
setopt noclobber                             # overwrite protection, use >| to force

export PROFILES_CONFIG_DIR=/opt/ConfigShell
if [ ! -d /opt/ConfigShell/. ] ; then
    echo 1>&2 "   Default PROFILES_CONFIG_DIR=/opt/ConfigShell not fullfilled, stopping.."
    return
fi
loadLibs
# debugSet # can be called of libs are loaded
[ "$errorSet" = 1 ] && echo error loading libary && return
debug zshenv: default lib loaded

# omz destroys path, now done after omz

debug zshenv setting environment variables

export ZSH_DISABLE_COMPFIX=true
export LESS='-iR'    # -i := searches are case insensitive; -R := Like -r, but only ANSI "color" escape sequences are output in "raw" form. The default is to display control characters using the caret notation.
export PAGER=less

export RSYNC_FLAGS="-rltDvu --modfiy-window=1"     # Windows FS updates file-times only every 2nd second
export RSYNC_SLINK_FLAGS="$RSYNCFLAGS --copy-links" # copy s-links as files
export RSYNC_LINK='--copy-links'                    # transform s-links to files

export VISUAL=vim
export EDITOR="$VISUAL"    # bsroot has no notion about VISUAL
export BLOCKSIZE=1K
export LC_ALL=en_US.UTF-8       # for ansible-vault which is required for git gee

export ZSHENV_LOADED=1

debug END dot.zshenv
# EOF
