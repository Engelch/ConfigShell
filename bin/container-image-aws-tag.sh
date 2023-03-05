#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2086
# shellcheck disable=SC2068
# shellcheck disable=SC1091

# Releases
#
# About
# container-image-aws-tag.sh - tag an image for AWS ECR
#

declare -r _appVersion="1.0.0"

#########################################################################################
# --- debug: Conditional debugging. All commands begin w/ debug.

function debugSet()             { DebugFlag=TRUE; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debug()                { [ "$DebugFlag" = "TRUE" ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = "TRUE" ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = "TRUE" ] && echo 'DEBUG:        ' "$*" 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = "TRUE" ] && echo 'DEBUG:            ' "$*" 1>&2 ; return 0; }

# stderr, exits -----------------------------------------------------
# function error()        { err 'ERROR:' $*; return 0; } # similar to err but with ERROR prefix and possibility to include
# Write an error message to stderr. We cannot use err here as the spaces would be removed.
function error()        { echo 'ERROR:'"$*" 1>&2;             return 0; }
function error4()       { echo 'ERROR:    '"$*" 1>&2;         return 0; }
function error8()       { echo 'ERROR:        '"$*" 1>&2;     return 0; }
function error12()      { echo 'ERROR:            '"$*" 1>&2; return 0; }

function errorExit()    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }
function exitIfErr()    { a="$1"; b="$2"; shift; shift; [ "$a" -ne 0 ] && errorExit "$b" App returned "$a $*"; }

function err()          { echo "$*" 1>&2; }                 # just write to stderr
function err4()         { echo '   ' "$*" 1>&2; }           # just write to stderr
function err8()         { echo '       ' "$*" 1>&2; }       # just write to stderr
function err12()        { echo '           ' "$*" 1>&2; }   # just write to stderr

# Existance checks -------------------------------------------------------
function exitIfBinariesNotFound()       { for file in "$@"; do command -v "$file" &>/dev/null || errorExit 253 binary not found: "$file"; done }
function exitIfPlainFilesNotExisting()  { for file in "$@"; do [ ! -f "$file" ] && errorExit 254 'plain file not found:'"$file" 1>&2; done }
function exitIfFilesNotExisting()       { for file in "$@"; do [ ! -e "$file" ] && errorExit 255 'file not found:'"$file" 1>&2; done }

####################################################################################
########### set the container command
####################################################################################

# setContainerCmd determines whether podman (preferred) or docker shall be used
# An error is created if none of them could be found.
# EXIT 10
function setContainerCmd() {
    which docker &>/dev/null && containerCmd=docker
    which podman &>/dev/null && containerCmd=podman
    [ -z "$containerCmd" ] && errorExit 10 container command could not be found
    debug Container command is "$containerCmd"
}

# setContainerName determines the name of the container image to be created.
# An error is created if none of them could be found.
# EXIT 12
function setContainerName() {
    if [ "$(/bin/ls | grep -c '^_name_.*' )" -eq 1 ] ; then
        containerName=$(/bin/ls | grep '^_name_.*' | sed 's/.*_name_//')
    else
        containerName=$(basename $PWD)
        [ "$containerName" = src ] && containerName=$(dirname $PWD | xargs basename)
    fi
    [ -z "$containerName" ] && errorExit 12 Container name could not be determined
    debug "containerName is $containerName"
}

# login2aws performs a login into AWS to make AWS ECR repositories available.
# The function is called by loginAwsIfInContainerfile
# EXIT 6    AWS_PROFILE not set
# EXIT 7    aws.cfg not found
# EXIT 8    AWS region not set
# EXIT 9    AWS registry not set
function login2aws() {
    [ -z "${AWS_PROFILE}" ] && errorExit 6 "AWS_PROFILE environment variable is required, in order to login to the docker registry"
    debug AWS_PROFILE set to "$AWS_PROFILE"

    # vars expected in aws.cfg
    #REGION=
    REGISTRY=
    ! [ -f aws.cfg ] && errorExit 7 "AWS Configuration aws.cfg not found"
    source "aws.cfg"

    [ -z "$REGION" ] && errorExit 8 "AWS Region not set"
    [ -z "$REGISTRY" ] && errorExit 9  "AWS Registry not set"

    debug "Login to AWS..."
    # login to AWS
    debug "aws ecr get-login-password --region ${REGION} | $containerCmd login --username AWS --password-stdin $REGISTRY"
    $DRY aws ecr get-login-password --region "${REGION}" | "$containerCmd" login --username AWS --password-stdin "$REGISTRY"
}

#########################


function usage() {
    1>&2 cat << HERE
USAGE
    container-image-aws-tag.sh [-D] [-n] [<<image:version>>]
    container-image-aws-tag.sh -h
    container-image-aws-tag.sh -V
OPTIONS
    -D :: enable debug
    -V :: show version and exit 2
    -h :: show usage/help and exit 1
    -n :: dry-run
HERE
}

# EXIT 1    usage/help
# EXIT 2    version
# EXIT 3    unknown option
function parseCLI() {
    while getopts "DVhn" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  err Debug enabled
                debugSet
                ;;
            V)  err $_appVersion
                exit 3
                ;;
            h)  usage
                exit 1
                ;;
            n)  DRY="echo"
                err DRY run enabled...
                ;;
            *)  err Help with "$app" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
}

function main() {
    exitIfBinariesNotFound pwd basename dirname version.sh container-image-build.sh
    declare -g DRY=
    declare -g REGISTRY=
    declare -g app="$(basename $0)"
    declare -g containerCmd=
    declare -g containerName=

    parseCLI "$@"
    shift $(( OPTIND - 1 ))  # not working inside parseCLI
    setContainerCmd
    if [ -z "$1" ] ; then
        setContainerName
        containerName="$containerName:$(version.sh)"
    else
        containerName="$1"
    fi
    login2aws
    debug "target to be pushed is $target"
    debug "would execute: $containerCmd tag $containerName $REGISTRY/$containerName"
    [ "$DebugFlag" = TRUE ] && echo press ENTER to execute && read -r
    $DRY $containerCmd tag "$containerName" "$REGISTRY/$containerName"
}

main "$@"

# EOF