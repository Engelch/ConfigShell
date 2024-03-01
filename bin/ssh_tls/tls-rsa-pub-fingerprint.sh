#!/usr/bin/env bash
# shellcheck disable=SC2155

# show fingerprint of public RSA key
function rsaPubFingerprint2() {
      if [ -n "$1" ] ; then 
         if [ -n "$DEBUG" ] ; then
            openssl rsa -modulus -text -noout -pubin -in "$1"  | \
               grep -E --colour=never '^(Modulus=|Exponent:)' | sed -E 's/Exponent: [0-9]+ \(//' | \
               sed 's/)//' | sed 's/Modulus=//' | sed 's/0x//' | \
               tr  '\n' ',' | sed -E 's/.$//'
            echo ; echo calculated checksum is:
         fi
         openssl rsa -modulus -text -noout -pubin -in "$1" | \
            grep -E --colour=never '^(Modulus=|Exponent:)' | sed -E 's/Exponent: [0-9]+ \(//' | \
            sed 's/)//' | sed 's/Modulus=//' | sed 's/0x//' | \
            tr  '\n' ',' | sed -E 's/.$//' | \
            sha256sum | \
            awk '{ print $1 }'
      else
         if [ -n "$DEBUG" ] ; then
            openssl rsa -modulus -text -noout -pubin | \
               grep -E --colour=never '^(Modulus=|Exponent:)' | sed -E 's/Exponent: [0-9]+ \(//' | \
               sed 's/)//' | sed 's/Modulus=//' | sed 's/0x//' | \
               tr  '\n' ',' | sed -E 's/.$//'
            echo ; echo calculated checksum is:
         fi
         openssl rsa -modulus -text -noout -pubin | \
            grep -E --colour=never '^(Modulus=|Exponent:)' | sed -E 's/Exponent: [0-9]+ \(//' | \
            sed 's/)//' | sed 's/Modulus=//' | sed 's/0x//' | \
            tr  '\n' ',' | sed -E 's/.$//' | \
            sha256sum | \
            awk '{ print $1 }'
      fi
}

function err() { 1>&2 echo "$@"; }

function usage() {
   err calculate the fingerprint of a public RSA key

   err $(basename "$0") "[ -v ]"
   err
   err '-v ::= show the filename'
}

unset VERBOSE
if [ "$1" = -h ] ; then
   usage
   exit 1
elif [ "$1" = -v ] ; then
   VERBOSE=TRUE
   shift
elif [ "$1" = -D ] ; then
   DEBUG=TRUE
   shift
fi
# echo num args $#
if [ $# -eq 0 ] ; then     # read from stdin
   rsaPubFingerprint2
else
   for file in "$@" ; do
      [ ! -f "$file" ] && err ERROR "$file" is not a regualar file && exit 10
      [ -n "$VERBOSE" ] && output="$(rsaPubFingerprint2 "$file")" && echo "$output $file"
      [ -z "$VERBOSE" ] && rsaPubFingerprint2 "$file"
   done
fi

# EOF
