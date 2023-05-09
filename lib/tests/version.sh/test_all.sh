#!/usr/bin/env sh
#

goAndExec() {
    cd "$(dirname "$1")" || exit 99
    # pwd
    ./"$(basename "$1")"
    cd ..
}

find . -name '*test.sh' | while read file; do goAndExec "$file" ; done
