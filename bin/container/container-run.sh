#!/usr/bin/env bash
# vim: set expandtab: ts=3: sw=3
# shellcheck disable=SC2155
#
# TITLE: container-run.sh
#
# DESCRIPTION: helper to run container with current directory set.
#
# LICENSE: MIT ©2026 engel-ch@outlook.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Changelog
# 1.1:
#  - add -v option for more variety
# 1.0:
#  - cleanup of code:
#    - Elements for ConfigShell loading into the container were removed.
#    - container-lib is not loaded anymore
# 0.2:
# - allowing -e key-value to support environment variables to be set inside/for the container
# - debug mode now shows the command that would be executed and waits for ENTER to continue
# 0.1:
# - initial version

# reverse helps to write a message in reverse mode
function reverse() {
  if [ "$TERM" = "xterm" ] || [ "$TERM" = "vt100" ] || [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "screen" ] ; then
      tput smso ; echo "$@" ; tput rmso
  else
    echo "$@"
  fi
}

function debug()        { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debugExecIfDebug()     { [ "$DebugFlag" = TRUE ] && $*; return 0; }
function debugSet()     { DebugFlag="TRUE"; return 0; }
function error()        { reverse 'ERROR:'"$@" 1>&2;  return 0; }
function errorExit()    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }
function exitIfBinariesNotFound()       { for file in "$@"; do command -v "$file" &>/dev/null || errorExit 253 binary not found: "$file"; done }

function usage()
{
    1>&2 cat <<HERE
NAME
    $_app
SYNOPSIS
    $_app [-D] [-e key=value] ... container [ <<command to be run inside of the container>> ]
    $_app -V
    $_app -h
VERSION
    $_appVersion
DESCRIPTION
    About:
    This commands runs a container, and it does not keep a container artifact
    afterwards. It shall enable to run commands from containers and hereby
    solve problems such as installing multiple psql or mysql client versions
    in parallel on a host.

    Mounting:
    1. The container mounts the root directory of the host os in the container
       under /wrk

    Container Command:
    The command uses podman is installed. Otherwise, if docker is found, it is
    used. Else, an error is created.

    The command can be called as container-run.sh or as cr.
OPTIONS
    -D      ::= enable debug output
    -V      ::= output the version number and exit with 127
    -v      ::= add a further docker/podman-like mountpoint
    -h      ::= show usage message and exit with exit with 0
    -e      ::= add an environmental option. The option can be supplied
                multiple times.

EXAMPLE CALL

    cr -D -e a=b -e b=c  terrastruct/d2 helloworld.d2 helloworld.jpg
    cr -D -v /tmp:/tmp -e b=c  terrastruct/d2 helloworld.d2 helloworld.jpg

EXIT Codes
    <<container exit value>>  ::= exit of normal execution
    0                         ::= exit of help
    1                         ::= unknown option error
    10                        ::= neither podman nor docker command found
    11                        ::= no container was specified
    127, 126                  ::= error, internal requirements not met
    253                       ::= commands not found, e.g. container command
HERE
}

function parseCLI() {
    while getopts "DVe:v:h" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  1>&2 echo Debug enabled ; DebugFlag="TRUE"
                ;;
            V)  1>&2 echo $_appVersion
                exit 0
                ;;
            e)  environmentOptions="$environmentOptions -e ${OPTARG}"
                ;;
            h)  usage ; exit 0
                ;;
            v)  fsMapOptions="$fsMapOptions -v ${OPTARG}"
                ;;
            *)
                1>&2 echo "Help with $_app -h"
                exit 1
                ;;
        esac
    done
}

# defineContainerCommand prints the found container command to stdout. It returns 0 if a
# container command could be found, otherwise 42.
function defineContainerCommand() {
    for possibleCmd in podman docker ; do
        if command -v "$possibleCmd" &> /dev/null ; then
            echo "$possibleCmd"
            return 0
        fi
    done
    return 42
}

function main() {
    declare -r _app=$(basename "${0}")
    declare -r _appDir=$(dirname "$0")
    declare -r _absoluteAppDir=$(cd "$_appDir" || exit 124 ; /bin/pwd)
    declare -r _appVersion="1.1.0"      # use semantic versioning
    export DebugFlag=${DebugFlag:-FALSE}
    fsMapOptions=
    environmentOptions=

    parseCLI "$@"
    shift "$(( OPTIND - 1 ))"  # not working inside parseCLI

    exitIfBinariesNotFound mktemp realpath
    containerCmd="$(defineContainerCommand)" || errorExit 253 defineContainerCommand could not determine container command
    debug "environment options are: $environmentOptions"
    debug "container-command is $containerCmd"

    debug args are "$@"
    [ -z "$1" ] && errorExit 11 No container to be run was specified.
    debug Executing, after pressing ENTER: "$containerCmd run -it --rm -u $(id -u):$(id -g) $fsMapOptions $environmentOptions -w /wrk -v $PWD:/wrk" "$@"
    debugExecIfDebug read
    # Disabling SC2086 as the variable environmentOptions shall be evaluated as potential multiple values.
    # shellcheck disable=SC2086
    "$containerCmd" run -it --rm -u "$(id -u):$(id -g)" $fsMapOptions $environmentOptions -w /wrk -v "$PWD:/wrk" "$@"
}

main "$@"

# EOF
