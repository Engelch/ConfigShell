#!/usr/bin/env bash
# vim: set expandtab: ts=3: sw=3
# shellcheck disable=SC2155
#
# TITLE: $_app
#
# DESCRIPTION: <see usage function below>
#
# LICENSE: MIT todo
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

#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"

# application-specific functions  ===============================================================================

function usage()
{
    cat <<HERE
NAME
    $_app
SYNOPSIS
    $_app [-D] [dir...]
    $_app -h
VERSION
    $_appVersion
DESCRIPTION
 ...
OPTIONS
 -D      ::= enable debug output
 -h      ::= show usage message and exit with exit code 1
HERE
}

function parseCLI() {
    while getopts "Dh" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  err Debug enabled ; debugSet
                ;;
            h)  usage ; exit 1
                ;;
            *)
                err Help with "$_app" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
}

function main() {
    # Variables
    declare -r _app=$(basename "${0}")
    declare -r _appDir=$(dirname "$0")
    declare -r _absoluteAppDir=$(cd "$_appDir" || exit 99 ; /bin/pwd)
    declare -r _appVersion="0.0.1"      # use semantic versioning
    export DebugFlag=${DebugFlag:-FALSE}
    # Requirements
    exitIfBinariesNotFound pwd basename dirname mktemp

    parseCLI "$@"
    shift "$(( OPTIND - 1 ))"  # not working inside parseCLI

    debug args are "$*"
    echo todo '(search and replace all todo accordingly)' here more....................
}

main "$@"

# EOF
