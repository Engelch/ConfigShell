#!/usr/bin/env bash
#

goAndExec() {
    cd "$(dirname "$1")" || exit 99
    # pwd
    ./"$(basename "$1")"
    cd ..
}

while read -r -d '' file; do
    goAndExec "$file"
done < <(find . -name '*test.sh' -print0)
