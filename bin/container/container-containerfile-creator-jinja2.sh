#!/usr/bin/env bash
#
# j2
# abouit: jinja2 for the CLI
# installation:
#     pip install j2cli
#     source: https://github.com/kolypto/j2cli
# binary: j2
# Alternative: brew install jinja2-cli
#

[ ! -f Containerfile.j2 ] && 1>&2 echo "Containerfile.j2 not found" && exit 1

export yearShort="$(date +%y)"
export monthNumber="$(date +%m)"
if [ "$(pwd | xargs dirname | xargs basename)" = src ] ; then
   export APP="$(pwd | xargs dirname | xargs dirname | xargs basename)"
else
   export APP="$(pwd | xargs dirname | xargs basename)"
fi

if [ "$1" = -n ] ; then # dry-run
   echo yearShort: "$yearShort"
   echo monthNumber "$monthNumber"
   echo APP "$APP"
 echo jinja2 -D monthNumber=${monthNumber} -D yearShort=${yearShort} Containerfile.j2 > Containerfile
else
   jinja2 -D monthNumber=${monthNumber} -D yearShort=${yearShort} Containerfile.j2 > Containerfile
fi
