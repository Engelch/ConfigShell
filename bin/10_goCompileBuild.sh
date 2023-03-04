#!/usr/bin/env bash

#  10_goCompileBuild.sh is considered to be started from a sub-directory where your
# go code resides, usually called Container. The scripts copies your go code, go.{mod,sum}
# and a packages directory to this Container directory. The packages directory must
# exist in advance.
#   If this is done, the script calls podman or if not found docker to build the image
# with the help of a docker bootstrap container. The name of the container is either
# the name of this directory (Container makes no sense) or derived from the flag file
# _name_<<imageName>>.

# As this command is still being tested, the command expects that enter is pressed before
# the build is being started.
#
# aws.cfg must be set as the container-image-build.sh script requires a
#
# Requirements:
#   container-image-build.sh
#   podman [] docker
#
#

declare -r app_version="0.1.1"

function error()        { echo 'ERROR:'"$*" 1>&2;             return 0; }
function error4()       { echo 'ERROR:    '"$*" 1>&2;         return 0; }
function error8()       { echo 'ERROR:        '"$*" 1>&2;     return 0; }
function error12()      { echo 'ERROR:            '"$*" 1>&2; return 0; }

function errorExit()    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }

####################################################################################
########### set the container command
####################################################################################

function setContainerCmd() {
    # Listed in order of ASCENDING preference (podman > docker)
    which docker &>/dev/null && containerCmd=docker
    which podman &>/dev/null && containerCmd=podman
    echo Container command is "$containerCmd"
}

function setContainerFile() {
    for file in Containerfile Dockerfile ; do
        [ -f "$file" ] && echo "Containerfile is $file" && containerFile="$file"
        break
    done
    [ -z "$containerFile" ] && errorExit 10 Could not find a Containerfile
}

function setContainerName() {
    if [ $(/bin/ls | grep -c '^_name_.*' ) -eq 1 ] ; then
        containerName=$(/bin/ls | grep '^_name_.*' | sed 's/.*_name_//')
    else
        containerName=$(basename $PWD)
        [ "$containerName" = src ] && containerName=$(dirname $PWD | xargs basename)
    fi
    echo "containerName is $containerName"
}

function login2aws() {

    ####################################################################################
    ########### check if AWS_PROFILE is set
    ####################################################################################

    [ -z "${AWS_PROFILE}" ] && \
        errorExit 6 "AWS_PROFILE environment variable is required, in order to login to the docker registry"

    echo AWS_PROFILE set to "$AWS_PROFILE"

    REGION=
    REGISTRY=
    ! [ -f aws.cfg ] && errorExit 7 "AWS Configuration aws.cfg not found"
    source aws.cfg

    [ -z "$REGION" ] && errorExit 8 "AWS Region not set"
    [ -z "$REGISTRY" ] && errorExit 9  "AWS Registry not set"

    echo "Login to AWS..."
    # login to AWS
    echo "aws ecr get-login-password --region ${REGION} | $containerCmd login --username AWS --password-stdin $REGISTRY"
    aws ecr get-login-password --region "${REGION}" | "$containerCmd" login --username AWS --password-stdin "$REGISTRY"
}

function loginAwsIfInContainerfile() {
    if [ $(grep -vE '^#' $containerFile | grep -Fc "amazonaws.com") -gt 0 ] ; then
        echo AWS elements found in containerfile
        login2aws
    else
        echo No AWS elements found
    fi
}

# Containerfile does not work well with packages referenced by s-links. Own, local packages
# are referenced using ./packages/<<pkg>>.  <<pkg>> might/should often be an s-link to
# a more global pkg for this project. This script copies the packages into the directory
# build_packages
function createBuildPackages() {
    [ -d ./ContainerBuild ] && echo deleting old ContainerBuild && /bin/rm -fr ./ContainerBuild # delete dir if existing
    mkdir -p ./ContainerBuild/src ./ContainerBuild/packages # fresh dir

    [ $(grep -Fc ./packages go.mod) -lt 1 ] && return # not copying
    for pkg in $(grep -F ./packages go.mod | awk '{ print $NF }') ; do
        rsync -av "$pkg" ./ContainerBuild/packages
    done
    rsync -av *.go go.mod go.sum ./ContainerBuild/src
}

#########################

# rsync -av ../go.sum ../go.mod ../*.go .
# [ ! -d ./packages/ ] && echo 1>&2 ./packages not existing && exit 1
# [ -d ../../packages ] && rsync -av ../../packages/ ./packages/

function main() {
    declare -g noStop
    declare -g containerCmd
    declare -g containerFile
    declare -g containerName
    [ "$1" = '-V' ] && err $app_version && exit 1
    [ "$1" = '-f' ] && NO_STOP="TRUE"

    setContainerCmd
    setContainerFile
    setContainerName
    loginAwsIfInContainerfile
    createBuildPackages
    echo container-image-build.sh -D $* -t amd64 "$containerName":$(version.sh)

    [ -z "$NO_STOP" ] && echo press ENTER to execute && read
    container-image-build.sh -D $* -t amd64 "$containerName":$(version.sh)
}

main "$@"

# EOF