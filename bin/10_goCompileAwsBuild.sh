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

####################################################################################
########### set the container command
####################################################################################

EXEC=
# Listed in order of ASCENDING preference (podman > docker)
which docker &>/dev/null &&
    EXEC=docker
which podman &>/dev/null &&
    EXEC=podman

echo Container command set to "$EXEC"

####################################################################################
########### check if AWS_PROFILE is set, the Containerfile is supposed to use an image from AWS
####################################################################################

[ -z "${AWS_PROFILE}" ] &&
    1>&2 echo "ERROR: AWS_PROFILE environment variable is required, in order to login to the docker registry" &&
    exit 6

echo AWS_PROFILE set to "$AWS_PROFILE"

REGION=
REGISTRY=
! [ -f aws.cfg ] &&
   1>&2 echo "ERROR: AWS Configuration aws.cfg not found" &&
   exit 7

source aws.cfg

[ -z "$REGION" ] &&
   1>&2 echo "AWS Region not set" &&
   exit 8
[ -z "$REGISTRY" ] &&
   1>&2 echo "AWS Registry not set" &&
   exit 9

echo "Login to AWS..."
# login to AWS
aws ecr get-login-password --region "${REGION}" | "$EXEC" login --username AWS --password-stdin "$REGISTRY"


#########################

rsync -av ../go.sum ../go.mod ../main.go .
[ ! -d ./packages/ ] && echo 1>&2 ./packages not existing && exit 1
[ -d ../../packages ] && rsync -av ../../packages/ ./packages/

if [ $(/bin/ls | grep -c '^_name_.*' ) -eq 1 ] ; then
    containerName=$(/bin/ls | grep '^_name_.*' | sed 's/.*_name_//')
else
    containerName=$(basename $PWD)
    [ "$containerName" = src ] && containerName=$(dirname $PWD | xargs basename)
fi


echo container-image-build.sh -D $* -t amd64 "$containerName":$(version.sh)
echo press ENTER to execute
read
container-image-build.sh -D $* -t amd64 "$containerName":$(version.sh)

