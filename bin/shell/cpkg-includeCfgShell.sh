#!/usr/bin/env bash

function warning()      { echo 'WARNING:'"$*" 1>&2;           return 0; }
function error()        { echo 'ERROR:'"$@" 1>&2;  return 0; }
function errorExit()    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }
function err()          { echo "$*" 1>&2; }                 # just write to stderr
function err4()         { echo '   ' "$*" 1>&2; }           # just write to stderr
function err8()         { echo '       ' "$*" 1>&2; }       # just write to stderr

export DebugFlag=${DebugFlag:-FALSE}
function debugSet()             { DebugFlag="TRUE"; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debugExecIfDebug()     { [ "$DebugFlag" = TRUE ] && "$*"; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' "$*" 1>&2 ; return 0; }

set -u 
readonly _appVersion="cpkg-includeCfgShell.sh v0.0.1"
upgradeScriptDir=~/.cpkg.d/upgrade
readonly _app=$(basename "$0")
systemInst=
upgradeScriptFilename=upgradeConfigshell.sh

function usage() {
    err SYNOPSIS:
    err4 "$_app" '[-D] [-V]'
    err4 "$_app" '[-h]'
    err4 "$_app" '[-s]   # remove optional s-link for ConfigShell upgrades from ~/.cpkg.d/upgrade'
    err DESCRIPTION
    err4 Install the dot-files of ConfigShell to the current user
    err OPTIONS
    err4 -D := enable debug
    err4 -V := show the version number
    err4 -h := show this help
}

case "${1:-}" in
    -h) usage ; exit 0 ;;
    -V) echo "$_appVersion" ; exit 0 ;;
    -D) debugSet ;;
    -s) systemInst=TRUE ;;
    *)  ;;
esac

if [ ! -d "$upgradeScriptDir" ] ; then
    mkdir -p "$upgradeScriptDir" || errorExit 1 "Cannot create directory "$upgradeScriptDir""
fi

cd "$upgradeScriptDir" || errorExit 2 "Cannot chdir to "$upgradeScriptDir""

if [ -e "$upgradeScriptFilename" ] ; then
    /bin/rm -f "$upgradeScriptFilename" || errorExit 3 "Cannot delete $upgradeScriptFilename"
fi

if [ -z "$systemInst" ] ; then
    ln -sv /opt/ConfigShell/bin/"$upgradeScriptFilename" . || errorExit 4 "Cannot create symlink to /opt/ConfigShell/$upgradeScriptFilename"
else
    echo 'Deleting s-link to from ~/.cpkg.d/ugprade to'" /opt/ConfigShell/bin/$upgradeScriptFilename"
    /bin/rm -f "$upgradeScriptFilename" || errorExit 5 "Cannot delete $upgradeScriptFilename"
fi
