#!/usr/bin/env sh
# shellcheck disable=SC2155

# About: create README.pdf and README.md from README.orig.md
# Requirements: ConfigShell, pandoc
# Author: engelch
# c230507
# u230508 (no version# of its own)

minor=$(md2pdf -V 2>&1 | sed -E 's/^[[:digit:]]+\.//' | sed -E 's/\..*//')      # minimal version: 0.1.0

[ "$minor" -lt 1 ] && 1>&2 echo 'ERROR: md2pdf at least required in version 0.1.0, exiting' && exit 3

# [ ! -f ../README.md ]      && 1>&2 echo 'ERROR: README.md not found, you might be in a wrong directory. Exiting.' && exit 1
[ ! -r README.orig.md ] && 1>&2 echo 'ERROR: Cannot find input file README.orig.md' && exit 2

grep -Ev '\\small'  README.orig.md | grep -Ev '\\normalsize' | grep -Ev '^colorlinks:' | \
    grep -Ev '^---' >| ../README.md
/opt/ConfigShell/bin/md2pdf -f -o ../README.pdf README.orig.md

# EOF
