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

case "${1:-}" in
   -D|--debug) debugSet; debug Debug enabled
      ;;
   -V|--version) echo "upgradeConfigshell2.sh version 1..00"; exit 0
      ;;
esac

CfgShellDir=/opt/ConfigShell/.

[ ! -d "$CfgShellDir" ] && errorExit 1 "Default directory $CfgShellDir not found, exiting"

[ "$(uname)" =  Darwin ] && { CfgDirUid=$(stat -f %u /opt/ConfigShell/bin) || errorExit 2 "Cannot determine UID of ConfigShell, this should never happen" ; }
[ "$(uname)" != Darwin ] && { CfgDirUid=$(stat -c %u /opt/ConfigShell/bin) || errorExit 2 "Cannot determine UID of ConfigShell, this should never happen" ; }

[ "$CfgDirUid" != "$UID" ] && errorExit 3 "This script is run with the UID $UID, but the ConfigShell tree has the UID $CfgDirUid, they should be the same"

debug ready to upgrade

cd /opt/ConfigShell && git pull || errorExit 4 "Cannot upgrade ConfigShell"

