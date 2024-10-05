#!/usr/bin/env bash
# shellcheck disable=SC2155 disable=SC2012 disable=SC2153

function loadLibs() {
    bashLib="/opt/ConfigShell/lib/bashlib.sh"
    [ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && return 1
    source "$bashLib"
    unset bashLib
    return 0
}

# helper for setupPath
function addPath() {
    debug8 START addPath
    [ ! -r "$2" ] && error12 "addPath: file not found: $2" && return
    [   -r "$2" ] && while IFS= read -r line; do
        line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
        if [ -d "$line" ] ; then 
            debug12 "ok found directory $line" ; 
            case "$1" in
                prepend) PATH="$line:$PATH" ;;
                append)  PATH="$PATH:$line" ;;
                *) error12 "addPath: unknown mode $1 for path $2" && return ;;
            esac
        else debug12 "not found: directory $line" ; fi
    done < "$2"
    debug8 END addPath
}

# setupPath sets the path
function setupPath2() {
    debug4 START setupPath
    [ $UID = 0 ] && debug4 root PATH initialisation &&  PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin
    [ $UID != 0 ] && debug4 normal user PATH init &&    PATH=./bin:/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin
    # add directories if existing for all platforms

    # 1
    addPath prepend "$PROFILES_CONFIG_DIR/ShellPaths/path.prepend.txt"
    # 2
    addPath prepend "$PROFILES_CONFIG_DIR/ShellPaths/path.$(uname).prepend.txt"
    # 3
    addPath prepend "$PROFILES_CONFIG_DIR/ShellPaths/path.$(uname).$(uname -m).prepend.txt"
    # 4
    addPath append "$PROFILES_CONFIG_DIR/ShellPaths/path.append.txt"
    # 5
    addPath append "$PROFILES_CONFIG_DIR/ShellPaths/path.$(uname).append.txt"
    # 6
    addPath append "$PROFILES_CONFIG_DIR/ShellPaths/path.$(uname).$(uname -m).append.txt"
    debug4 END setupPath
}

# =========================================================================================


# setupPath sets the path
function setupPath1() {
    debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
    local _POTENTIAL_DIR
    # set up initial path
    PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin
    if [ "$UID" = 0 ] ; then
        debug8 root PATH initialisation
        PATH=/sbin:/usr/sbin:/bin:/usr/bin
    fi
    # add directories if existing for all platforms
    setupPath2
    if [ -f  "$HOME/.rbenv/version" ] ; then
      debug "rbenv version file found"
      ruby_version=$(cat "$HOME/.rbenv/version" | head -n 1)
      debug "  ruby_version is $ruby_version"
      if [ -d "$HOME/.rbenv/versions/$ruby_version/bin" ] ; then
         PATH="$HOME/.rbenv/versions/$ruby_version/bin:$PATH"
         debug "  adding path for ruby version $ruby_version"
      else
         echo "  .rbenv/version file found with version $ruby_version, but appropriate directory with installation not found." &> /dev/stderr
      fi
   fi 
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
    export COLUMNS   # required for diff2

    export KUBECTL=kubectl
    if which docker 2&>/dev/null ; then
        export CONTAINER=docker
        debug8 CONTAINER $CONTAINER
    fi
    if which podman 2&>/dev/null ; then
        export CONTAINER=podman
        debug8 CONTAINER $CONTAINER
        alias docker=podman
    fi
    export BASH_SILENCE_DEPRECATION_WARNING=1   # OSX suppress bash warning
    export LS_COLOUR='-G'
    export LSCOLORS=Exfxcxdxbxegedabagacad # change directory colour 1st letter; see man ls(1)

    export PROFILES_CONFIG_DIR=$(ls -l "$HOME/.bashrc" | awk '{ print $NF }' | xargs dirname)
    [ -z "$PROFILES_CONFIG_DIR" ] && error PROFILES_CONFIG_DIR not set



    debug8 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

function main() {
    loadLibs
    [ "$?" != 0 ] && echo error loading libary && return
    debug default lib loaded
    debug4 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'

    # seem to be inherited to sub-shells
    set -o ignoreeof                             # prevent ^d logout
    set -o noclobber                             # overwrite protection, use >| to force


   export PROFILES_CONFIG_DIR=/opt/ConfigShell
   if [ ! -d /opt/ConfigShell/. ] ; then
      echo 1>&2 "   Default PROFILES_CONFIG_DIR=/opt/ConfigShell not fullfilled, stopping.."
      return
   fi

   envVars     # load environment variables (above), required for PROFILES_CONFIG_DIR below, must be done after PATH setup
   setupPath1

    # shellcheck source=/dev/null
    [ -z "$NO_bashrc" ] && [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"    # start all the normal files

    # iterm @OSX
    # shellcheck source=/dev/null
    [ -r "$HOME/.iterm2_shell_integration.bash" ] && [ "$(uname)" = "Darwin" ] && source "$HOME/.iterm2_shell_integration.bash"
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    # terraform
    [ -f /opt/homebrew/bin/terraform ] && complete -C /opt/homebrew/bin/terraform terraform
    debug4 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

# debugSet
main "$@"

# EOF
