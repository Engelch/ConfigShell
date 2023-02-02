#!/usr/bin/env bash
# shellcheck disable=SC2155

function prvFingerprint() {
   openssl  rsa  -noout -modulus -text -in "$1" | \
        grep -E --colour=never '(Modulus=|publicExponent:)' | \
        sed -E 's/^.*Exponent: [0-9]+ \(//' | \
        sed 's/)//' | \
        sed 's/Modulus=//' | \
        sed 's/0x//' | \
        tr  '\n' ',' | \
        sed -E 's/.$//' | \
        sed 's/^public//' | \
        sed 's/publicExponent:/Exponent:/' | sha256sum | awk '{ print $1 }'
}


function err() { 1>&2 echo "$@"; }

function usage() {
   err show fingerprintf of RSA private key
   err
   err "$(basename $0) [ -v ]"
   err
   err '-v ::= show the filename'
}

unset VERBOSE
if [ "$1" = -h ] ; then
   usage
   exit 1
elif [ "$1" = -v ] ; then       # show filenames
   VERBOSE=TRUE
   shift
fi
for file in "$@" ; do
   [ ! -f "$file" ] && err ERROR "$file" is not a regualar file && exit 10
   [ -n "$VERBOSE" ] && prvFingerprint "$file" | sed "s/$/ $file/"
   [ -z "$VERBOSE" ] && prvFingerprint "$file"

done

# EOF
