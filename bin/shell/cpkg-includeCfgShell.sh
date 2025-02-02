#!/usr/bin/env bash

function warning()      { reverse 'WARNING:'"$*" 1>&2;           return 0; }
function error()        { reverse 'ERROR:'"$@" 1>&2;  return 0; }
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

upgradeScriptDir=~/.cpkg.d/upgrade

if [ ! -d "$upgradeScriptDir" ] ; then
    mkdir -p "$upgradeScriptDir" || errorExit 1 "Cannot create directory "$upgradeScriptDir""
fi

cd "$upgradeScriptDir" || errorExit 2 "Cannot chdir to "$upgradeScriptDir""

if [ -e upgradeConfigshell.sh ] ; then
    /bin/rm -f ./upgradeConfigshell.sh || errorExit 3 "Cannot delete upgradeConfigshell.sh"
fi

ln -s /opt/ConfigShell/bin/upgradeConfigshell.sh . || errorExit 4 "Cannot create symlink to /opt/ConfigShell/upgradeConfigshell.sh"

