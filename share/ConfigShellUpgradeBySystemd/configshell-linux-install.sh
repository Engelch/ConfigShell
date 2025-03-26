#!/usr/bin/env bash
# vim: set expandtab: ts=3: sw=3
# shellcheck disable=SC2155
#
# TITLE: configshell-linux-instaoll.sh
#
# DESCRIPTION: <see usage function below>
#
# LICENSE: MIT ©2025 engel-ch@outlook.com
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

function error()        { echo 'ERROR:'"$@" 1>&2;  return 0; }
function errorExit()    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }
function exitIfBinariesNotFound()       { for file in "$@"; do command -v "$file" &>/dev/null || errorExit 253 binary not found: "$file"; done }

function usage()
{
    1>&2 cat <<HERE
NAME
    $_app
SYNOPSIS
    $_app [-D] [dir...]
    $_app [-V]
    $_app -h
VERSION
    $_appVersion
DESCRIPTION
    Install ConfigShell on a Linux host with a specific user configshell and
    a systemd timer to update ConfigShell
OPTIONS
    -D      ::= enable debug output
    -V      ::= output the version number to stderr and exit with 0
    -h      ::= show usage message to stderr and exit with 0
HERE
}

# lineExisting
# EXIT 100, 101, 102
function lineExisting() {
  [ $# != 2 ] && 1>&2 echo "wrong call to lineExisting, args are $#, expected:2"  && exit 100
  [ ! -e "$2" ] && 1>&2 echo "file $2 not existing"  && exit 101
  [ ! -r "$2" ] && 1>&2 echo "file $2 not readable"  && exit 102
  echo output is "$(grep -Ec "$1" "$2")"
  [ "$(grep -Ec "$1" "$2")" -gt 0 ] && return 0
  return 1
}

function createUserGroup() {
  lineExisting "^configshell:" /etc/group || \
    { echo group creation configshell ; sudo groupadd configshell ; }
  echo group configshell existing 
  lineExisting "^configshell:" /etc/passwd || \
    { echo user creation configshell ; sudo useradd -r -g configshell -s /bin/bash configshell ; } 
  echo user configshell existing 
}

function createCleanConfigShell() {
  :
}

function createSystemdTimer() {
  :
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
            # v)  verbose=TRUE
            #     ;;
            *)
                1>&2 echo "Help with $_app -h"
                exit 1  # Exit abnormally.
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

    parseCLI "$@"               # cannot use fn-s from loadLibs
    shift "$(( OPTIND - 1 ))"   # not working inside parseCLI

    exitIfBinariesNotFound mktemp journalctl systemctl # break if no systemd system

    createUserGroup
    createCleanConfigShell
    createSystemdTimer
}

main "$@"

# EOF
