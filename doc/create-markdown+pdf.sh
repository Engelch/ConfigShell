#!/usr/bin/env sh
# shellcheck disable=SC2155

# About: create README.pdf and README.md from README.orig.md
# Requirements: ConfigShell, pandoc
# Author: engelch
# c230507
# u230508 (no version# of its own)

minor=$(md2pdf -V 2>&1 | sed -E 's/^[[:digit:]]+\.//' | sed -E 's/\..*//')      # minimal version: 0.1.0

[ "$minor" -lt 1 ] && 1>&2 echo 'ERROR: md2pdf at least required in version 0.1.0, exiting' && exit 3

find . -depth 1 -name '*.orig.md' -print0 | while read -r -d '' origFile ; do
    destMdFile=$(basename "$origFile" | sed 's,.orig,,')
    destPdfFile=${destMdFile/.md/.pdf}
    echo "$origFile → $destMdFile + $destPdfFile"
    if [ "$1" != '-n' ] ; then
        grep -Ev '\\small'  "$origFile"  | grep -Ev '\\normalsize' | grep -Ev '^colorlinks:' | \
        grep -Ev '^---' >| "../$destMdFile"
        /opt/ConfigShell/bin/md2pdf -f -o "../$destPdfFile" "$origFile"
    fi
done

find . -depth 1 -name '*.marp.md' -print0 | while read -r -d '' origFile ; do
    destMdFile=$(basename "$origFile" | sed 's,.marp,,')
    destPdfFile=${destMdFile/.md/.pdf}
    echo "$origFile → $destMdFile + $destPdfFile"
    if [ "$1" != '-n' ] ; then
        grep -Ev '\\small' "$origFile" | grep -Ev '\\normalsize' | grep -Ev '^colorlinks:' | \
        grep -Ev '^---' >| "../$destMdFile"
        marp2pdf  "$origFile"
        mv -v "${origFile/.md/.pdf}" "../${origFile/.marp.md/.pdf}"
    fi
done
# EOF
