#!/usr/bin/env bash
# shellcheck disable=SC2155

#########################################################################################
# --- debug: Conditional debugging. All commands begin w/ debug.

function debugSet()             { DebugFlag=TRUE; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' "$*" 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:            ' "$*" 1>&2 ; return 0; }

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

# EXIT 10
function setContainerCmd() {
    debug "${FUNCNAME[0]} .............."
    declare -g EXEC=
    # Listed in order of ASCENDING preference (podman > docker)
    which docker &>/dev/null &&
        EXEC="docker"
    which podman &>/dev/null &&
        EXEC="podman"
    [ -z "$EXEC" ] && errorExit 10 container command could not be found
}

function setContainerName() {
    debug "${FUNCNAME[0]} .............."
    declare -g containerName
    if [ $(/bin/ls | grep -c '^_name_.*' ) -eq 1 ] ; then
        containerName=$(/bin/ls | grep '^_name_.*' | sed 's/.*_name_//')
    else
        containerName=$(basename $PWD)
        [ "$containerName" = src ] && containerName=$(dirname $PWD | xargs basename)
    fi
}

function usage() {
    1>&2 cat << HERE
USAGE
    10_simpleBuild.sh [ -D ] [ -a ] [ -t targetPlatform ] [ -n ]
    10_simpleBuild.sh -h
    10_simpleBuild.sh -V
OPTIONS
    -D :: enable debug
    -V :: show version and exit 2
    -h :: show usage/help and exit 1
    -a :: does AWS login based on AWS_PROFILE and/or aws.cfg
    -n :: dry-run
HERE
}

# EXIT 1    usage/help
# EXIT 2    version
# EXIT 3    unknown option
function parseCLI() {
    declare -r defaultTargetEnv="-t amd64"
    declare -g extTargetEnv=
    declare -g awsSupport=
    declare -g DRY=
    while getopts "DVahnt:" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  err Debug enabled
                debugSet
                ;;
            V)  err $_appVersion
                exit 3
                ;;
            a)  awsSupport=TRUE
                debug AWS support activated
                ;;
            h)  usage
                exit 1
                ;;
            n)  DRY=echo
                err DRY run enabled...
                ;;
            t)  extTargetEnv="$extTargetEnv -t $OPTARG"
                debug setting target env to "$OPTARG"
                ;;
            *)  err Help with "$_app" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
    [ -z "$extTargetEnv" ] && extTargetEnv="$defaultTargetEnv"
}

####################################################################################
########### Check if AWS_PROFILE, REGION, REGISTRY is set, an AWS image is considered to be specified
########### in the Containerfile.
####################################################################################

# EXIT 20 no aws.cfg
function setAws() {
    declare -g REGION=
    declare -g REGISTRY=
    declare -g AWS_PROFILE=

    debug "${FUNCNAME[0]} .............."
    ! [ -f aws.cfg ] && errorExit 20  "ERROR: AWS Configuration aws.cfg not found"
    source aws.cfg

    [ -z "${AWS_PROFILE}" ] && errorExit 21 "ERROR: AWS_PROFILE environment variable is required, in order to login to the docker registry" &&
    debug4  AWS_PROFILE set to "$AWS_PROFILE"
    export AWS_PROFILE
    [ -z "$REGION" ] && errorExit 22 "AWS Region not set"
    debug4 AWS region set to "$REGION"
    export AWS_REGION
    [ -z "$REGISTRY" ] && errorExit 23 "AWS Registry not set"
    debug4 AWS registry set to "$REGISTRY"
    export AWS_REGISTRY
}


function buildImage() {
    debug container-image-build.sh -D $* "$extTargetEnv" "$containerName":$(version.sh)
    $DRY container-image-build.sh -D $* "$extTargetEnv" "$containerName":$(version.sh)
}


function main() {
    readonly _app=$(basename "$0")
    readonly _appDir=$(dirname "$0")
    readonly _absoluteAppDir=$(cd "$_appDir" || errorExit 1 cannot determine absolute path of app_dir; /bin/pwd)
    readonly _appVersion="2.0.0" # use semantic versioning
    export DebugFlag=${DebugFlag:-FALSE}
    exitIfBinariesNotFound pwd basename dirname version.sh container-image-build.sh
    parseCLI "$@"
    shift $(( OPTIND - 1 ))  # not working inside parseCLI
    debug args are "$*"
    setContainerCmd
    debug Container command set to "$EXEC"
    setContainerName
    debug Container name set to "$containerName"
    [ -n "$awsSupport" ] && setAws
    buildImage
}

main "$@"