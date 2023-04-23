#!/usr/bin/env bash

version=1.1.0
flagFile=

function isOlderThanHours() {
    # $1 hours, uint, >0
    # $2 filename to check
    [ $# -ne 2 ] && 1>&2 echo Wrong call to isOlderThanHours with args $* && return 10
    [ "$1" -lt 1 ] && 1>&2 echo hours argument $1 not correct && return 11
    [ ! -f "$2" ] && 1>&2 echo Filename $2 is not a plain file && return 12
    local currentTime=$(date -u '+%s')
    local fileMTime=$(date  -u -r $2 '+%s')
    local hoursInSecs=$(( $1 * 3600 ))
    local fileAndHours=$(( $fileMTime + $hoursInSecs ))
    #1>&2 echo current $currentTime, fileMTime $fileMTime, hoursInSecs $hoursInSecs, file+hours $fileAndHours
    [ $fileAndHours -ge $currentTime ] && return 1
    # [ $fileAndHours -ge $currentTime ] && 1>&2 echo file not older than n hours, no action && return 1
    #1>&2 echo file is older than n hours, should upgrade
    return 0
}

function conditionalUpdateGitRepo() {
    local res
    echo -n doing updateConfigShell $* ..... ' '
    [ ! -d "$1" ] && 1>&2 echo supplied argument not a directory $1 && return 10
    if [ -f $flagFile ] ; then
        isOlderThanHours ${UPDATE_CONFIGSHELL_FREQUENCE:-4} $flagFile; res=$?
        if [ $res -eq 0 ] ; then
            echo upgrading...
            cd "$1"
            git pull
            res=$?
            touch $flagFile
            cd $OLDPWD
        else 
            echo NOT trying to upgrade
            res=0
        fi
    else
        echo upgrading no flag-file existing
        touch $flagFile 
        cd "$1" 
        git pull
        res=$?
        cd $OLDPWD
    fi
    return $res
}

function main() {
    # update configShell
    local res
    if [ "$1" = '-V' ] || [ "$1" = '--version' ] ; then echo $version ; exit 1 ; fi
    if [ ! -z "$1" ] ; then
        res=0
        for file in $* ; do
            echo in loop res $res
            flagFile=$HOME/.upgradeConfigShell.$(basename $file)
            [ ! -d "$file" ] && 1>&2 echo Supplied argument $file not a directory && (( res += 60 )) && continue
            conditionalUpdateGitRepo "$file" ; (( res += $? ))
            echo res is $res
        done
        return $res
    else 
        dir=$(dirname $(readlink -f $HOME/.bashrc))
        flagFile=$HOME/.upgradeConfigShell.$(basename $dir)
        conditionalUpdateGitRepo $dir
        return $?
    fi
    # should never happen
    return 90
}

main $*

# EOF
