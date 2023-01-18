#!/usr/bin/env bash
# shellcheck disable=SC2155


function rsaPrv2PubKey2() { openssl rsa -in "$1" -pubout; }

function err() { 1>&2 echo "$@"; }

function usage() {
   err calculate the public key from a private RSA key
   err
   err $(basename "$0") "[ -v ]"
   err
   err '-v ::= show the filename'
}

if [ "$1" = -h ] ; then
   usage
   exit 1
else
   for file in "$@" ; do
      [ ! -f "$file" ] && err ERROR "$file" is not a regualar file && exit 10
      rsaPrv2PubKey2 "$file"
   done
fi

# EOF
