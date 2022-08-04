#!/usr/bin/env bash

flagFile=$HOME/.updateConfigShell

function isOlderThanHours() {
    # $1 hours, uint, >0
    # $2 filename to check
    [ $# -ne 2 ] && 1>&2 echo Wrong call to isOlderThanHours with args $* && return 10
    [ "$1" -lt 1 ] && 1>&2 echo hours argument $1 not correct && return 11
    [ ! -f "$2" ] && 1>&2 echo Filename $2 is not a plain file && return 12
    local currentTime=$(date -u '+%s')
    local fileMTime=$(date '+%s' -u -r $2)
    local hoursInSecs=$(( $1 * 3600 ))
    local fileAndHours=$(( $fileMTime + $hoursInSecs ))
    #echo current $currentTime, fileMTime $fileMTime, hoursInSecs $hoursInSecs, file+hours $fileAndHours
    [ $fileAndHours -ge $currentTime ] && echo no upgrade required && return 1
    echo upgrading
    return 0
}

function updateConfigShell() {
    echo doing updateConfigShell $*
    [ ! -d "$1" ] && 1>&2 echo supplied argument not a directory $1 && return 10
    if [ -f $flagFile ] ; then
        isOlderThanHours 4 $flagFile && cd "$1" && git pull ; res=$?
    else
        touch $flagFile && cd "$1" && git pull ; res=$?
    fi
    cd $OLDPWD
    return $res
}

function main() {
    # update configShell
    if [ ! -z "$1" ] ; then
        updateConfigShell "$1"
        return $?
    fi
    if [ -d /opt/ConfigShell/.git ] ; then
        updateConfigShell /opt/configShell
        return $?
    elif [ -f $HOME/.bashrc ] ; then
        _basename=$(dirname $(readlink -f $HOME/.bashrc))
        if [ -d "$_basename"/.git ] ; then
            updateConfigShell "$_basename"
            return $?
        fi
    fi
    1>&2 echoCould not find ConfigShell
    return 90
}

main $*

# EOF
