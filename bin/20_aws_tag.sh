#!/usr/bin/env bash
#
#


function usage() {
    echo usage
    cat <<- HERE
    20_aws_tag.sh [ tag ]
    20_aws_tag.sh -h

    OPTIONS
    -h :== help mode

    REQUIREMENTS
    - The command calls the container-image-aws-tag_push.sh script to tag the images.
    - version.sh is callable (e.g. in ConfigShell) and delivers a proper version number.

    FUNCTIONALITY
    Without an argument, the commands detects the actual version using the version.sh script.
    The image is tagged by <<AWS_REPOSITORY>>/image_name:$(version.sh)
    The AWS_REPOSITORY is detected by the above AWS script using the aws.cfg file.
    The image name is either detected by the current directory name (transformed to lower case)
    or if existing by a flag file _name_nameOfImage.

    Alternatively, an argument can be specified. Then, the tag name is the supplied argument.
HERE
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
    usage
    exit 255
fi

if [ $(/bin/ls | grep -c '^_name_.*' ) -eq 1 ] ; then
    containerName=$(/bin/ls | grep '^_name_.*' | sed 's/.*_name_//')
else
    containerName=$(basename $PWD)
    [ "$containerName" = src ] && containerName=$(dirname $PWD | xargs basename)
fi

if [ -n "$1" ] ; then
   echo container-image-aws-tag_push.sh "$containerName":"$1"
   echo press ENTER to continue
   read
   container-image-aws-tag_push.sh "$containerName":"$1"

else
   echo container-image-aws-tag_push.sh "$containerName":$(version.sh)
   echo press ENTER to continue
   read
   container-image-aws-tag_push.sh "$containerName":$(version.sh)
fi
