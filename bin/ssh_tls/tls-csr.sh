#!/usr/bin/env bash
# shellcheck disable=SC2155
# CHANGELOG
# 1.3: change sed from , to % as we have files containing commata...., replaced by AWK  sed "s,^,$file:,"

#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
#########################################################################################

function tlsCsr2() {
   local file;
   for file in "$@"; do
      openssl req -in "$file"  -noout -utf8 -text | xx=$file awk ' BEGIN { file=ENVIRON["xx"] } { printf("%s:%s\n", file, $0) }' | egrep -v '.*:.*:.*:'
   done
}

function csrShowFingerprint() {
   local file
   for file in "$@"; do
      # [ -n "$VERBOSE" ] && echo -n "$file":
      debug pubkey is $(openssl req -in "$file" -noout -pubkey)
      openssl req -in "$file" -noout -pubkey | tls-rsa-pub-fingerprint.sh
   done
}

function usage() {
   cat <<HERE
DESCRIPTION
   Show CSR fields (aka attributes) or show the fingerprint for a CSR. The
   fingerprint will only be based on the contained public key using the
   modulus and the exponent of it.

SYNOPSIS
   $(basename "$0") -h
   $(basename "$0") [ -D ] [ -v ] <<file>>
   $(basename "$0") [ -D ] [ -f ] [ -v ] <<file>>

OPTIONS
   -h ::= show help
   -D ::= show debug information
   -v ::= split output CSRs by a separator line
   -f ::= show the fingerprint of the public key inside the CSR
HERE
}

# exit codes 1..9
function parseCLI() {
   while getopts "VDhvf" options; do         # Loop: Get the next option;
      case "${options}" in                    # TIMES=${OPTARG}
         V)    1>&2 echo "1.3.0"
               exit 2
               ;;
         D)    debugSet
               debug Debug is on
               ;;
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
      for file in "$@" ; do # fingerprint output
         [ -n "$VERBOSE" ] && output="$(csrShowFingerprint "$file")" && echo "$output $file"
         [ -z "$VERBOSE" ] && csrShowFingerprint "$file"
      done
   else
      for file in "$@" ; do # output csr
         [ ! -f "$file" ] && err ERROR "$file" is not a regualar file && exit 10
         tlsCsr2 "$file"
      done
   fi
}

main "$@"

# EOF
