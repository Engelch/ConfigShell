#!/usr/bin/env bash

function err() {
  1>&2 echo $*
}

function errorExit() {
  val=$1
  shift
  err 'ERROR:'$*
  exit $val
}

############################

DRY_RUN=
[ "$1" = -n ] && DRY_RUN=echo && shift &&  echo DRU_RUN mode

#[ $# -lt 1 ] &&
#    1>&2 echo "ERROR: expected at least 1 argument" &&
#    1>&2 echo "Usage: ${0} image-tag [, Dockerfile]" &&
#    1>&2 echo "       Dockerfile ist of the format 'Dockerfile.proj'" &&
#    1>&2 echo "       It is expected that a directory proj exists." &&
#    exit 1
#
#[ -z $DRY_RUN -a $# -ge 3 ] &&
#    1>&2 echo "ERROR: at most 2 arguments supported" &&
#    1>&2 echo "Usage: ${0} [-n] image-tag [, Dockerfile]" &&
#    exit 2
# [ ! -z $DRY_RUN -a $# -ge 4 ] &&
#     1>&2 echo "ERROR: at most 2 arguments supported" &&
#     1>&2 echo "Usage: ${0} [-n] image-tag [, Dockerfile]" &&
#     exit 2

# required for tagging, but could also be done in ciPush where it could make sense to support multiple
# destinations
. .containersettings || {
    1>&2 echo "ERROR: expected file .containersettings with key-value pairs: REGISTRY=, REGION="
    exit 3
}

[ -z "${REGISTRY}" ] &&
    1>&2 echo "ERROR: REGISTRY variable is not set in .containersettings" &&
    exit 4

[ -z "${REGION}" ] &&
    1>&2 echo "ERROR: REGION variable is not set in .containersettings" &&
    exit 5

[ -z "${AWS_PROFILE}" ] &&
    1>&2 echo "ERROR: AWS_PROFILE environment variable is required, in order to login to the docker registry" &&
    exit 6

EXEC=

# Listed in order of ASCENDING preference (podman > docker)
which docker &>/dev/null &&
    EXEC=docker
which podman &>/dev/null &&
    EXEC=podman

DOCKERFILE="Dockerfile.*"
if [ $# -ge 1 ]; then
    DOCKERFILE="$*"
    [ ! -e "${DOCKERFILE}" ] &&
        echo "ERROR: specified Dockerfile does not exist: ${DOCKERFILE}" &&
        exit 7
fi

# aws login required for cias-ubuntu image
aws ecr get-login-password --region ${REGION} | $EXEC login --username AWS --password-stdin ${REGISTRY}


for one_file in $DOCKERFILE; do 

    ! [[ ${one_file} =~ ^Dockerfile\.[-_0-9a-zA-Z\.]+$ ]] && errorExit 20 argument does not follow filename specification:${one_file}
    # if the Dockerfile is of the form Dockerfile.xxx.yyy, then xxx is supposed to be the supported architeture
    IMAGE_ARCHITECTURE="--arch=amd64"
    if [ "$(echo ${one_file} | egrep '\..*\.' | wc -l)" -gt 0 ] ; then
      echo special image architecture, value is $(echo ${one_file} | egrep '\..*\.'  | wc -c)
      IMAGE_ARCHITECTURE="--arch=$(echo ${one_file} | cut -d . -f 2)" && \
      echo IMAGE_ARCHITECTURE set to ${IMAGE_ARCHITECTURE}
      PROJECT=$(echo ${one_file} | cut -d . -f 3)
    else
      PROJECT=$(echo ${one_file} | cut -d . -f 2)
      echo project is $PROJECT
    fi

    if [ ! -d ${PROJECT} ] ; then
      errorExit 10 echo project directory ${PROJECT} not found
    fi
    cd ${PROJECT}
    version=$(version.sh)
    [ -z "$version" ] && errorExit 11 echo could not set version
    cd -
    echo version is $version
    IMAGE_TAG="$version"

    IMAGE_NAME="$(echo "${one_file}" | awk -F'.' '{ print $2; }')"
    IMAGE_URL=${REGISTRY}/${IMAGE_NAME}:$version
    IMAGE_URL_LATEST=${REGISTRY}/${IMAGE_NAME}:latest

    echo "----------------------------------------------"
    echo "Selected runtime: ${EXEC}, architecture: ${IMAGE_ARCHITECTURE}, image: ${IMAGE_URL}"

    $DRY_RUN $EXEC push "${IMAGE_URL}" || errorExit 25 "failed to push image $version"
    $DRY_RUN $EXEC push "${IMAGE_URL_LATEST}" || errorExit 25 "failed to push image latest"
done
