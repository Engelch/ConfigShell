#!/usr/bin/env bash
# vim: set expandtab: ts=3: sw=3
# shellcheck disable=SC2155
#
# TITLE: container-push.sh
#
# DESCRIPTION: helper to push container, also supporting wildcards for the container name.
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
# - add -r flag: auto-retry Huawei SWR pushes on "net/http: timeout awaiting response headers"
# 1.0:
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
    $_app [-D] [-r] container ...
    $_app -V
    $_app -h
VERSION
    $_appVersion
DESCRIPTION
    About:
    This command pushes a container to a container registry. The container argument is
    matched against 'REPOSITORY:TAG' as a full (anchored) match. Shell-style wildcards
    '*' (any sequence) and '?' (single char) are supported, e.g.:
    $_app 'docker.io/debian:*'
    will push all images whose repository is docker.io/debian regardless of the tag.
OPTIONS
    -D      ::= enable debug output
    -r      ::= auto-retry on Huawei SWR (myhuaweicloud.com) pushes when the
                push fails with 'net/http: timeout awaiting response headers'.
                Max attempts default is 10, override via env CRP_HUAWEI_RETRY_MAX.
    -V      ::= output the version number and exit with 0
    -h      ::= show usage message and exit with 0

EXAMPLE CALL

    $_app "docker.io/debian:*"
    $_app -D "docker.io/debian:*"

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
    while getopts "DrVh" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  1>&2 echo Debug enabled ; DebugFlag="TRUE"
                ;;
            r)  HuaweiRetryFlag="TRUE"
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

# pushContainer performs a single push. When HuaweiRetryFlag is TRUE and the image targets
# myhuaweicloud.com, it retries up to CRP_HUAWEI_RETRY_MAX times, but only when the failure
# stderr contains exactly "net/http: timeout awaiting response headers".
function pushContainer() {
    local image="$1"
    local maxAttempts="${CRP_HUAWEI_RETRY_MAX:-10}"
    local retryable=FALSE
    if [ "$HuaweiRetryFlag" = TRUE ] && [[ "$image" == *myhuaweicloud.com* ]] ; then
        retryable=TRUE
    fi
    if [ "$retryable" != TRUE ] ; then
        "$containerCmd" push "$image"
        return $?
    fi
    local attempt=1 rc tmpErr
    while : ; do
        tmpErr=$(mktemp)
        "$containerCmd" push "$image" 2> >(tee "$tmpErr" >&2)
        rc=$?
        if [ "$rc" -eq 0 ] ; then
            rm -f "$tmpErr"
            return 0
        fi
        if grep -q -F 'net/http: timeout awaiting response headers' "$tmpErr" \
                && [ "$attempt" -lt "$maxAttempts" ] ; then
            attempt=$((attempt + 1))
            1>&2 reverse "RETRY: Huawei SWR timeout on '$image', attempt $attempt/$maxAttempts"
            rm -f "$tmpErr"
            continue
        fi
        rm -f "$tmpErr"
        return "$rc"
    done
}

function main() {
    declare -r _app=$(basename "${0}")
    declare -r _appDir=$(dirname "$0")
    declare -r _absoluteAppDir=$(cd "$_appDir" || exit 124 ; /bin/pwd)
    declare -r _appVersion="1.1"      # use semantic versioning
    export DebugFlag=${DebugFlag:-FALSE}
    export HuaweiRetryFlag=${HuaweiRetryFlag:-FALSE}

    parseCLI "$@"
    shift "$(( OPTIND - 1 ))"  # not working inside parseCLI

    exitIfBinariesNotFound mktemp realpath
    containerCmd="$(defineContainerCommand)" || errorExit 253 defineContainerCommand could not determine container command
    debug "container-command is $containerCmd"

    debug args are "$@"
    [ -z "$1" ] && errorExit 11 No container to be run was specified.
    # Find the containers to be pushed, supporting wildcards in the container name.
    containersToBePushed=()
    for container in "$@" ; do
        debug "container to be pushed is $container"
        # Convert shell-style glob (*, ?) to an anchored ERE by first escaping regex metachars.
        pattern=$(printf '%s' "$container" \
            | sed -e 's/\\/\\\\/g' \
                  -e 's/[].^$(){}|+[]/\\&/g' \
                  -e 's/\*/.*/g' \
                  -e 's/?/./g')
        pattern="^${pattern}\$"
        debug "regex pattern is $pattern"
        # shellcheck disable=SC2086
        for foundContainer in $($containerCmd images --format '{{.Repository}}:{{.Tag}}' | grep -E "$pattern") ; do
            debug "found container to be pushed is $foundContainer"
            containersToBePushed+=("$foundContainer")
        done
    done
    for container in "${containersToBePushed[@]}" ; do
        debug Executing, after pressing ENTER: "$containerCmd push $container"
        debugExecIfDebug read
        pushContainer "$container"
    done
}

main "$@"

# EOF
