#!/usr/bin/env bash
# shellcheck disable=SC2155 disable=SC2012 disable=SC2153

######################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && return  # no exit for bash_profile or bashrc
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
##########################

function setupPathsFromFiles() {
   debug12 "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'

   # 1
    debug12 "PREPENDING global PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.prepend.txt" ] && \
       while IFS= read -r line ; do
         line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs) # xargs for trimming outer spaces
         if [ -d "$line"  ] ; then debug12 "Found path $line ::prepending" ; PATH="$line:$PATH"
         else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.prepend.txt"

    # 2
    debug12 "PREPENDING os-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).prepend.txt" ] && \
       while IFS= read -r line &>/dev/null; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
          if [ -d "$line" ] ; then debug12 "Found path $line ::prepending" ; PATH="$line:$PATH"
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).prepend.txt"

    # 3
    debug12 "PREPENDING architecture-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).prepend.txt" ] && \
       while IFS= read -r line &>/dev/null; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
          if [ -d "$line" ] ; then debug12 "Found path $line ::prepending" ; PATH="$line:$PATH"
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).prepend.txt"

    # 4
    debug12 "APPENDING global PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.append.txt" ] && \
       while IFS= read -r line; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
          if [ -d "$line" ] ; then debug12 "Found path $line ::appending" ; PATH="$PATH:$line"
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.append.txt"

    # 5
    debug12 "APPENDING os-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).append.txt" ] && \
       while IFS= read -r line; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
          if [ -d "$line" ] ; then debug12 "Found path $line ::appending" ; PATH="$PATH:$line" ;
          else debug12 "NOT found path $line" ; fi
       done < "$PROFILES_CONFIG_DIR/Shell/path.$(uname).append.txt"

    # 6
    debug12 "APPENDING architecture-specific PATH ENTRIES ........"
    [ -r "$PROFILES_CONFIG_DIR/Shell/path.$(uname).$(uname -m).append.txt" ] && \
       while IFS= read -r line; do
          line=$(echo "$line" | sed -e "s,^~,$HOME," | sed -e "s,^\$HOME,$HOME," | xargs)
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
    for file in /etc/bash_completion /usr/local/etc/bash_completion /opt/homebrew/etc/bash_completion /usr/share/bash-completion/bash_completion ; do
      [ -f "$file" ] && debug found bash_completion "$file", sourcing... && source "$file"
    done

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
