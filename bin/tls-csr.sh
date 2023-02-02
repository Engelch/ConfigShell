#!/usr/bin/env bash
# shellcheck disable=SC2155

function error()        { echo 'ERROR:'"$*" 1>&2;             return 0; }
function error4()       { echo 'ERROR:    '"$*" 1>&2;         return 0; }
function error8()       { echo 'ERROR:        '"$*" 1>&2;     return 0; }
function errorExit()    { EXITCODE=$1 ; shift; error "$*" ; exit "$EXITCODE"; }
function err()          { 1>&2 echo "$@"; }

function tlsCsr2() {
   local file;
   for file in $*; do
      openssl req -in "$file"  -noout -utf8 -text | sed "s,^,$file:," | egrep -v '.*:.*:.*:'
   done
}

function csrShowFingerprint() {
   local file
   for file in "$*"; do
      # [ -n "$VERBOSE" ] && echo -n "$file":
      openssl req -in "$file" -noout -pubkey | tls-rsa-pub-fingerprint.sh
   done
}

function usage() {
   err Show CSR values
   err
   err $(basename "$0") "-h"
   err $(basename "$0") "[ -v ] <<file>>"
   err $(basename "$0") "[ -f ] [ -v ] <<file>>"
   err
   err '-h ::= show help'
   err '-v ::= split output CSRs by a separator line'
   err '-f ::= show the fingerprint of the public key inside the CSR'
}

# exit codes 1..9
function parseCLI() {
   while getopts "hvf" options; do         # Loop: Get the next option;
      case "${options}" in                    # TIMES=${OPTARG}
         v)    VERBOSE=TRUE
               ;;
         f)    FINGERPRINT=TRUE
               ;;
         h)    usage ; exit 1
               ;;
         *)    errorExit 2 Wrong argument supplied. Help with "$_app" -h
               ;;
      esac
   done
}

# exit code ≥ 10
function main() {
   unset FINGERPRINT
   unset VERBOSE
   parseCLI $*
   shift $(($OPTIND - 1))  # not working inside parseCLI
   if [ -n "$FINGERPRINT" ] ; then
      for file in "$@" ; do

         [ -n "$VERBOSE" ] && csrShowFingerprint "$file" | sed "s/$/ $file/"
         [ -z "$VERBOSE" ] && csrShowFingerprint "$file"
      done
   else
      for file in "$@" ; do
         [ ! -f "$file" ] && err ERROR "$file" is not a regualar file && exit 10
         tlsCsr2 "$file"
      done
   fi
}

main "$@"

# EOF
