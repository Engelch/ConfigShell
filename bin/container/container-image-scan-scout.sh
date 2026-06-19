#! /usr/bin/env bash

containerimage="$1"
[ -z "$1" ] && 1>&2 echo ERROR:containerImage:version must be specified && exit 1
current_date="$(date +%y%m%d)"
readonly outputFile="scout:${current_date}-$containerimage.txt"
echo creating file "$outputFile"
if [ -f "$HOME/.docker/scout/docker-scout" ] ; then
    "$HOME/.docker/scout/docker-scout" quickview "$containerimage" | tee  "$outputFile"
else
    docker scout quickview "$containerimage" | tee  "$outputFile"
fi
[ ${PIPESTATUS[0]} -ne 0 ] && /bin/rm -f "$outputFile"
exit ${PIPESTATUS[0]}