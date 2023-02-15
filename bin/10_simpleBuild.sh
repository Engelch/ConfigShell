#!/usr/bin/env bash


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
########### check if AWS_PROFILE is set
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

