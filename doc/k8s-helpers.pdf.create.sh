#!/usr/bin/env bash

_file=k8s-helpers
[ -n "$1" ] && _file="$1"

if [ ! -f "$_file".md  ] ; then
    echo "$_file.md not found."
    exit 1
fi
if [  "$_file".md -nt "$_file".pdf ] ; then
    # --defaults is required to read the metadata from the file's first YAML block
    pandoc -o "$_file".pdf "$_file".md --defaults "$_file".md
else
    echo "$_file.pdf is up to date."
fi
