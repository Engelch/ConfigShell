#!/usr/bin/env bash
# vim: set expandtab: ts=3: sw=3
# shellcheck disable=SC2155
#
# TITLE: container-run.sh
#
# DESCRIPTION: helper to run container with current directory set.
#
# LICENSE: MIT ©2023 engel-ch@outlook.com
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

function loadLibs() {
    #########################################################################################
    # ConfigShell lib 1.1 (codebase 1.0.0)
    bashLib="/opt/ConfigShell/lib/bashlib.sh"
    [ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
    # shellcheck source=/opt/ConfigShell/lib/bashlib.sh
    source "$bashLib"

    #########################################################################################
    containerLib="/opt/ConfigShell/lib/container-image.lib.sh"
    [ ! -f "$containerLib" ] && 1>&2 echo "container-library $containerLib not found" && exit 126
    # shellcheck source=/opt/ConfigShell/lib/container-image.lib.sh
    source "$containerLib"
}

function usage()
{
    1>&2 cat <<HERE
NAME
    $_app
SYNOPSIS
    $_app [-D] container [ <<command to be run inside of the container>> ]
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
       under /y
    2. The working directory is kept to be the one before the container start

    Container Command:
    The command uses podman is installed. Otherwise, if docker is found, it is
    used. Else, an error is created.

    Known Limitations:
    - The command cannot be used without adjustments for absolutte paths as
      the / of the host-OS becomes to /y inside the container.
OPTIONS
    -D      ::= enable debug output
    -V      ::= output the version number and exit with 127
    -h      ::= show usage message and exit with exit with 0
EXIT Codes
    <<container exit value>>  ::= exit of normal execution
    0                         ::= exit of help
    1                         ::= unknown option error
    10                        ::= neither podman nor docker command found
    11                        ::= no container was specified
    127, 126                  ::= error, internal requirements not met
HERE
}

function parseCLI() {
    while getopts "DVh" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  1>&2 echo Debug enabled ; DebugFlag="TRUE"
                ;;
            V)  1>&2 echo $_appVersion
                exit 0
                ;;
            h)  usage ; exit 0
                ;;
            *)
                1>&2 echo "Help with $_app -h"
                exit 1
                ;;
        esac
    done
}

function main() {

    declare -r _app=$(basename "${0}")
    declare -r _appDir=$(dirname "$0")
    declare -r _absoluteAppDir=$(cd "$_appDir" || exit 124 ; /bin/pwd)
    declare -r _appVersion="0.1.0"      # use semantic versioning
    export DebugFlag=${DebugFlag:-FALSE}

    parseCLI "$@"
    shift "$(( OPTIND - 1 ))"  # not working inside parseCLI

    loadLibs
    exitIfBinariesNotFound mktemp realpath
    setContainerCmd

    debug args are "$@"
    [ -z "$1" ] && errorExit 11 No container to be run was specified.
    currentDir="$(realpath "$(pwd)")"
    "$containerCmd" run -it --rm --workdir /y/"$currentDir" -v "/:/y"  "$@"
}

main "$@"

# EOF
