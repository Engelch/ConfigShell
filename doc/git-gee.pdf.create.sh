#!/usr/bin/env bash

if [ ! -f git-gee.pandoc2.md ] ; then
    echo "git-gee.pandoc2.md not found."
    exit 1
fi
if [  git-gee.pandoc2.md -nt git-gee.pdf ] ; then
    # --defaults is required to read the metadata from the file's first YAML block
    pandoc -o git-gee.pdf git-gee.pandoc2.md --defaults git-gee.pandoc2.md
else
    echo "git-gee.pdf is up to date."
fi
