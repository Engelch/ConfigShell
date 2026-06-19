#!/usr/bin/env bash
# create a template.json file
# call: j2 Containerfile.j2 template.json

set -u

year="$(date +%y)"
month="$(date +%m)"
echo  '{ "yearShort" : "'$year'", "monthNumber" : "'$month'" }' > template.json

