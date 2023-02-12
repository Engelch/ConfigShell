#!/usr/bin/env bash
#
# $0 '[ -n ] [ -p | --push ] imagename:tagname
# -n dry-run


####################################################################################
###########  help mode
####################################################################################

[ -z '$*' ]         && echo $(basename "$0") '[ -p | --push ] imagename:tagname' && exit 1
[ '$1' = '-h' ]     && echo $(basename "$0") '[ -p | --push ] imagename:tagname' && exit 1
[ '$1' = '--help' ] && echo $(basename "$0") '[ -p | --push ] imagename:tagname' && exit 1

####################################################################################
###########  dry mode
####################################################################################

DRY=
[ "$1" = -n ] && DRY=echo && echo DRY mode enabled && shift

####################################################################################
###########  check if to push
####################################################################################

PUSH=
[ "$1" = '-p' ]  && PUSH=TRUE && shift
[ "$1" = '--push' ] && PUSH=TRUE && shift
[ -n "$PUSH" ] && echo PUSH mode enabled

####################################################################################
###########  dry mode (after push option)
####################################################################################

[ "$1" = -n ] && DRY=echo && echo DRY mode enabled && shift

####################################################################################
########### set the container command
####################################################################################

EXEC=
# Listed in order of ASCENDING preference (podman > docker)
which docker &>/dev/null &&
    EXEC=docker
which podman &>/dev/null &&
    EXEC=podman

####################################################################################
########### check if AWS_PROFILE is set
####################################################################################

[ -z "${AWS_PROFILE}" ] &&
    1>&2 echo "ERROR: AWS_PROFILE environment variable is required, in order to login to the docker registry" &&
    exit 6

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

# login to AWS
aws ecr get-login-password --region "${REGION}" | "$EXEC" login --username AWS --password-stdin "$REGISTRY"

# check if image to be tagged is existing
#

tag1=$(echo "$1" | sed 's/:.*//')
tag2=$(echo "$1" | sed 's/.*://')
[ -z "$tag1" ] && 1>&2 echo tag1 could not be set && exit 11
[ -z "$tag2" ] && 1>&2 echo tag2 could not be set && exit 12
[ $("$EXEC" image ls | grep "$tag1" | grep -c "$tag2" ) -lt 1 ] && 1>&2 echo could not find image to tag && exit 10

####################################################################################
########### tagging
####################################################################################

echo "$EXEC" tag "$1" "$REGISTRY"/"$1"
$DRY "$EXEC" tag "$1" "$REGISTRY"/"$1"

####################################################################################
########### optional push
####################################################################################

[ -n "$PUSH" ] && echo "$EXEC" push "$REGISTRY"/"$1"
[ -n "$PUSH" ] && $DRY "$EXEC" push "$REGISTRY"/"$1"

