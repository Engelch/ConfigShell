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

#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
#########################################################################################
containerLib="/opt/ConfigShell/lib/container-image.lib.sh"
[ ! -f "$containerLib" ] && 1>&2 echo "container-library $containerLib not found" && exit 126
# shellcheck source=/opt/ConfigShell/lib/container-image.lib.sh
source "$containerLib"
unset containerLib
#########################################################################################

#########################


function usage() {
    1>&2 cat << HERE
USAGE
    container-image-aws-tag.sh [-D] [-n] [<<image:version>>]
    container-image-aws-tag.sh -h
    container-image-aws-tag.sh -V
DESCRIPTION
    Tags an exiting image to be pushed to AWS ECR. If started with
    the -D option, the tagging command will be shown before and
    an ENTER is required, before it will executed. The -n option
    is an alternative to that.
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
        if [ -d ContainerBuild/src ] ; then
            containerName="$containerName:$(version.sh ContainerBuild/src)"
        else
            containerName="$containerName:$(version.sh)"
        fi
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
