#!/usr/bin/env bash

containerimage="$1"
[ -z "$1" ] && 1>&2 echo ERROR:containerImage:version must be specified && exit 1
current_date="$(date +%y%m%d)"
readonly outputFile="snyk:${current_date}-$containerimage.txt"
echo creating file "$outputFile"
snyk container test "$containerimage" | tee  "$outputFile"
[ ${PIPESTATUS[0]} -ne 0 ] && /bin/rm -f "$outputFile"
exit ${PIPESTATUS[0]}