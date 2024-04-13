#! /usr/bin/env bash

# shellcheck disable=SC2155
#
# ABOUT
#   container frontend for podman or docker to abstract from the actual version
#
#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
#########################################################################################

if which podman ; then
    exec podman "$@" 
elif which docker ; then
    exec docker "$@"
else
    errorExit 1 Neither podman nor docker found.
fi

# eof
