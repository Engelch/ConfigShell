#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2086
# shellcheck disable=SC2068
# shellcheck disable=SC1091
# shellcheck disable=SC2154 # as variables are assigned in the library file

# Changelog
# 2.0
# - dependency checking introduced for higher consistency
#   - stop building if the Containerfile.j2 is newer than Containerfile
#   - Dockerfile - if existing - is supposed to be an s-link to Containerfile (currently, not yet enforced)
#   - if staged container build with golang, then check if the golang go version is identical with ../go.mod
# 1.5
# - additional automatic detection of golang mode for compilation by searching the Containerfile for `golang:true`
# 1.4
# - golang mode: move to create tar-balls for the Containerfile as this fixes problems with s-links
# 1.3.1
# - version# factored out to lib file
# - error if not started in a dir called Container
# - improved doc in script
# 1.3.0
# - container-image common code factored out to lib file
# - improved doc in script
# - all container-image versions use the same version number
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
#    the go files for container-staged compilation.
#    The files are copied to resolve s-link issues. If the build fails, the ContainerBuild/ subdirectory
#    can be inspected. Each new call to container-image-build will remove an existing ContainerBuild/ directory.
# 6. it determines the version to be created.
# 7. it calls cotnainer-image-build to build the container image for the given architecture and version and date
#
# Requirements:
#   podman [] docker
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
    echo in createBuildPackages
    [ -d ./ContainerBuild ] && debug deleting old ContainerBuild && $DRY /bin/rm -fr ./ContainerBuild # delete dir if existing
    $DRY mkdir -p ./ContainerBuild/ # fresh dir

    [ "$DebugFlag" = "TRUE" ] && $DRY rsync -avL ../versionFilePattern ../*.go ../go.mod ../go.sum ../packages ./ContainerBuild/
    [ "$DebugFlag" != "TRUE" ] && $DRY rsync -aL ../versionFilePattern ../*.go ../go.mod ../go.sum ../packages ./ContainerBuild/

    # [ "$(grep -Fc \./packages ContainerBuild/src/go.mod)" -lt 1 ] && return # no references for local packages, not copying

    # # for all ./packages/xyz listed, copy them to ./ContainerBuild/packages
    # grep -F \./packages ContainerBuild/src/go.mod | awk '{ print $NF }' | cut -d '/' -f 3 | while IFS= read -r pkg ; do
    #     [ "$DebugFlag" = "TRUE" ] && $DRY rsync -av "../../packages/$pkg" ./ContainerBuild/packages
    #     [ "$DebugFlag" != "TRUE" ] && $DRY rsync -a "../../packages/$pkg" ./ContainerBuild/packages
    #     ln -s ../packages ./ContainerBuild/src/packages
    # done
    pushd ContainerBuild || errorExit 30 'Oops, ContainerBuild not found.'
    if [ "$(uname)" = Darwin ] ; then
        gtar cf ../ContainerBuild.tar .     # tar OSX creates problems with xattr
    else
        tar cf ../ContainerBuild.tar .
    fi
    popd || errorExit 31 'createBuildPackages:Could not return to previous directory'
}

# optionallyCreateGoSetup checks if to create ContainerBuild directory for go compilation
function optionallyCreateGoSetup() {
    # go-mode if specified on CLI
    [ -n "$goCompilation" ] && debug 'go-compilation selected from CLI' && createBuildPackages && return
    # go-mode if .go files in containerFile
    [ "$(grep -vE '^#' $containerFile | grep -Fc '.go')" -gt 0 ] && debug 'go compilation found' && createBuildPackages && return
    # enable go-mode if a comment,... in the Containerfile contains golang:true
    [ "$(grep -c 'golang:true' Containerfile)" -gt 0 ] && debug 'goland:true found ⇒ golang compilation' && createBuildPackages
}

# EXIT 20
function checkForGoCompatibility() {
    if [ "$(grep -ci 'FROM *golang:' "$containerFile")" -gt 0 ] ; then 
        debug golang compilation detected
        debug selected line from Containerfile: $(grep -i 'FROM *golang:' "$containerFile")
        golangversion="$(grep -i 'From *golang:' "$containerFile" | sed 's/.*golang://' | sed 's/ .*//' | sed 's/-.*//')"
        debug "golangversion $golangversion"
        if [ -f ../go.mod ] ; then
            modGoVersion="$(grep -i 'go ' ../go.mod | sed 's/go *//' | sed 's/ //g')"
            debug modGoVersion "$modGoVersion"
            if [ ! "$golangversion" = "$modGoVersion" ] ; then 
                1>&2 echo "$containerFile version is of golang is: $golangversion"
                1>&2 echo "go version in ../go.mod is: $modGoVersion"
                1>&2 echo 'Version differ; exiting'
                exit 20
            fi
        fi
    fi
}

#########################


function usage() {
    1>&2 cat << HERE
USAGE
    container-image-build.sh [-D] [-a] [-g] [-t targetPlatform ] [-n] [-x]
    container-image-build.sh -h
    container-image-build.sh -V
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
    -x :: do not exit if Containerfile.j2 is newer than the Containerfile
HERE
}

# EXIT 1    usage/help
# EXIT 2    version
# EXIT 3    unknown option
function parseCLI() {
    declare -r defaultTargetEnv="--platform=linux/amd64"
    declare -g extTargetEnv=
    declare -g awsSupport=
    declare -g goCompilation=
    declare -g DRY=
    while getopts "DVaghnt:x" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  err Debug enabled
                debugSet
                ;;
            V)  err "$_appVersion"
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
            x)  skipTestContainerfileJ2="TRUE"
                debug enable skip for newer Containerfile.j2
                ;;
            *)  err Help with "$app" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
    [ -z "$extTargetEnv" ] && extTargetEnv="$defaultTargetEnv"  # set amd64 if no architecture was set
}

function exitIfNotInContainer() {
    local dirLeave=$(basename "$(pwd)")
    [ "$dirLeave" != 'Container' ] && errorExit 22 container-image-build.sh is supposed to be started from a directory named Container.
}

# EXIT 20
function main() {
    exitIfBinariesNotFound pwd basename dirname version.sh
    [ "$(uname)" = Darwin ]  && exitIfBinariesNotFound gtar
    declare -g app="$(basename $0)"
    declare -g containerCmd=''
    declare -g containerFile=''
    declare -g containerName=''

    parseCLI "$@"
    shift $(( OPTIND - 1 ))  # not working inside parseCLI

    exitIfNotInContainer

    setContainerCmd
    setContainerFile
    checkForGoCompatibility
    setContainerName
    loginAwsIfInContainerfile
    optionallyCreateGoSetup
    unset _version
    if [ -d ContainerBuild ] ; then
        _version="$(version.sh ContainerBuild)"
    else
        _version="$(version.sh)"
    fi
    [ -z "$_version" ] && errorExit 20 "Could not detect version using version.sh"
    debug "Version is: $_version"
    date="$(date -u +%y%m%d_%H%M%S)"
    debug "Date tag set to $date"
    debug Would execute: "$containerCmd" buildx build  $@ $extTargetEnv --progress plain -t "$containerName":"$_version" -t "$containerName:latest" -t "$containerName:$date" .

    [ "$DebugFlag" = TRUE ] && echo press ENTER to execute && read -r
    $DRY "$containerCmd" buildx build $@ $extTargetEnv --progress plain -t "$containerName":"$_version" -t "$containerName:latest" -t "$containerName:$date" .
}

main "$@"

# EOF
