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

function usage() {
    err $(basename $0) '<<image-name>>...'
    err
    err delete matching images. Matching is done by grep.
}

[ -z "$1" ] && errorExit 1 expecting one argument to match container images

# Listed in order of ASCENDING preference (podman > docker)
which docker &>/dev/null &&
CONTAINER_TOOL=docker
which podman &>/dev/null &&
CONTAINER_TOOL=podman

for _image in $* ; do
    $CONTAINER_TOOL container ls -a | grep $_image  | awk '{ print $3 }' | xargs $CONTAINER_TOOL container rm --force
done

# eof
