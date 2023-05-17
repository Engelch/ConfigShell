#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2086
# shellcheck disable=SC2068
# shellcheck disable=SC1091

# Releases
# 1.1.0
# - calling containerCmd directly to build container images
# - -t .... had to be changed to --arch when calling $containerCmd build ...
#
# 1.0.0
# - shellcheck disablement added
# - old 10_ scripts included to one version
# - shellcheck executed
#
# About
# container-build.sh is a front-end for container-image-build.sh
# 1. it determines the command to use for container-related commands
# 2. it determines the name of the container-file
# 3. it determines the name of the image to be created
# 4. it checks if the container-file contains hints for AWS and in such a case performs login to AWS
# 5. it checks if the container-file contains hints for go compilation and in such a case prepares
#    the go files for container-staged compilation
# 6. it determines the version to be created.
# 7. it calls cotnainer-image-build to build the container image for the given architecture and version and date
#
# Requirements:
#   container-image-build.sh
#   podman [] docker#
#

declare -r _appVersion="1.2.0"

#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
#########################################################################################

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

# setContainerFile determines the Containerfile or Dockerfile to be used.
# An error is created if none of them could be found.
# EXIT 11
function setContainerFile() {
    for file in Containerfile Dockerfile ; do
        [ -f "$file" ] && debug "Containerfile is $file" && containerFile="$file"
        break
    done
    [ -z "$containerFile" ] && errorExit 11 Could not find a Containerfile
}

# setContainerName determines the name of the container image to be created.
# An error is created if none of them could be found.
# EXIT 12
function setContainerName() {
    if [ "$(/bin/ls | grep -c '^_name_.*' )" -eq 1 ] ; then
        containerName=$(/bin/ls | grep '^_name_.*' | sed 's/.*_name_//')
    else
        containerName=$(dirname $PWD | xargs basename)
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
    REGION=
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

# loginAwsIfInContainerfile checks if amazonaws.com is found in the container-file.
# If so, it tries to log in into AWS.
function loginAwsIfInContainerfile() {
    [ -n "$awsSupport" ] && debug flag aws support set && login2aws && return
    if [ "$(grep -vE '^#' $containerFile | grep -Fc 'amazonaws.com')" -gt 0 ] ; then
        debug AWS elements found in containerfile
        login2aws
    else
        debug No AWS elements found, not logging in
    fi
}

# Containerfile does not work well with packages referenced by s-links. Own, local packages
# are referenced using ./packages/<<pkg>>.  <<pkg>> might/should often be an s-link to
# a more global pkg for this project. This script copies the packages into the directory
# ContainerBuild
function createBuildPackages() {
    [ -d ./ContainerBuild ] && debug deleting old ContainerBuild && $DRY /bin/rm -fr ./ContainerBuild # delete dir if existing
    $DRY mkdir -p ./ContainerBuild/src ./ContainerBuild/packages # fresh dir

    [ "$DebugFlag" = "TRUE" ] && $DRY rsync -av ../*.go ../go.mod ../go.sum ./ContainerBuild/src
    [ "$DebugFlag" != "TRUE" ] && $DRY rsync -a ../*.go ../go.mod ../go.sum ./ContainerBuild/src
    [ "$(grep -Fc ./packages ContainerBuild/src/go.mod)" -lt 1 ] && return # not copying
    grep -F ./packages ContainerBuild/src/go.mod | awk '{ print $NF }' | cut -d '/' -f 3 | while IFS= read -r pkg ; do
        [ "$DebugFlag" = "TRUE" ] && $DRY rsync -av "../../packages/$pkg" ./ContainerBuild/packages
        [ "$DebugFlag" != "TRUE" ] && $DRY rsync -a "../../packages/$pkg" ./ContainerBuild/packages
    done
}

# optionallyCreateGoSetup checks if to create ContainerBuild directory for go compilation
function optionallyCreateGoSetup() {
    [ -n "$goCompilation" ] && createBuildPackages && return
    [ "$(grep -vE '^#' $containerFile | grep -Fc '.go')" -gt 0 ] && $DRY createBuildPackages
}

#########################


function usage() {
    1>&2 cat << HERE
USAGE
    container-build.sh [ -D ] [ -a ] [ -g ] [ -t targetPlatform ] [ -n ]
    container-build.sh -h
    container-build.sh -V
OPTIONS
    -D :: enable debug
    -V :: show version and exit 2
    -h :: show usage/help and exit 1
    -a :: explicit AWS login based on AWS_PROFILE and/or aws.cfg,
          normally checked by container-file
    -g :: explicitly say, compile for go,
          normally checked by container-file
    -n :: dry-run
    -t :: set the target environment, default amd64
HERE
}

# EXIT 1    usage/help
# EXIT 2    version
# EXIT 3    unknown option
function parseCLI() {
    declare -r defaultTargetEnv="--arch=amd64"
    declare -g extTargetEnv=
    declare -g awsSupport=
    declare -g goCompilation=
    declare -g DRY=
    while getopts "DVaghnt:" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  err Debug enabled
                debugSet
                ;;
            V)  err $_appVersion
                exit 3
                ;;
            a)  awsSupport="TRUE"
                debug AWS support activated
                ;;
            g)  goCompilation="TRUE"
                ;;
            h)  usage
                exit 1
                ;;
            n)  DRY="echo"
                err DRY run enabled...
                ;;
            t)  extTargetEnv="$extTargetEnv --arch=$OPTARG"
                debug setting target env to "$OPTARG"
                ;;
            *)  err Help with "$app" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
    [ -z "$extTargetEnv" ] && extTargetEnv="$defaultTargetEnv"
}

# EXIT 20
function main() {
    exitIfBinariesNotFound pwd basename dirname version.sh container-image-build.sh
    declare -g app="$(basename $0)"
    declare -g containerCmd=
    declare -g containerFile=
    declare -g containerName=

    parseCLI "$@"
    shift $(( OPTIND - 1 ))  # not working inside parseCLI

    setContainerCmd
    setContainerFile
    setContainerName
    loginAwsIfInContainerfile
    optionallyCreateGoSetup
    unset _version
    if [ -d ContainerBuild/src ] ; then
        cd ContainerBuild/src
        _version="$(version.sh)"
        cd ../..
    else
        _version="$(version.sh)"
    fi
    [ -z "$_version" ] && errorExit 20 "Could not detect version using version.sh"
    debug "Version is: $_version"
    date="$(date -u +%y%m%d_%H%M%S)"
    debug "Date tag set to $date"
    debug Would execute: "$containerCmd" build $@ $extTargetEnv -t "$containerName":"$_version" -t "$containerName:latest" -t "$containerName:$date" .

    [ "$DebugFlag" = TRUE ] && echo press ENTER to execute && read -r
    $DRY "$containerCmd" build $@ $extTargetEnv -t "$containerName":"$_version" -t "$containerName:latest" -t "$containerName:$date" .
}

main "$@"

# EOF