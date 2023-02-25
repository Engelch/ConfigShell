#!/usr/bin/env bash
# show colours supported by terminal
# by default 4 columns output, can be changed by $1
 BREAK=4
[ ! -z $1 ] && BREAK=$1
for i in {0..255} ; do
    printf "\x1b[38;5;${i}mcolour${i} \t"
    if [ $(( i % $BREAK )) -eq $(($BREAK-1)) ] ; then
        printf "\n"
    fi
done
