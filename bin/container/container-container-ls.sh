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
    err $(basename $0) '[ <<image-name>>...] '
    err
    err list matching or all images.
}

# Listed in order of ASCENDING preference (podman > docker)
which docker &>/dev/null &&
CONTAINER_TOOL=docker
which podman &>/dev/null &&
CONTAINER_TOOL=podman


$CONTAINER_TOOL container ls -a $*
# eof
