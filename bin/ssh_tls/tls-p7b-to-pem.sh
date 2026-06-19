#! /usr/bin/env bash

input="$1"
[ ! -f "$1" ] && input="-"
#outfile=$(basename "$1" .p7b).pem
#[ -f "$outfile" ] && echo output file already existing > /dev/stderr && exit 2
openssl pkcs7  -inform DER -print_certs -in "$input"
