#!/usr/bin/env bash

dir="$HOME/Applications (Parallels)"

[ -d "$dir" ] && 1>&2 echo "$dir", deleting... && /bin/rm -fr "$dir"

# EOF
