#!/usr/bin/env -S bash --norc --noprofile

export DebugFlag=${DebugFlag:-FALSE}
function debugSet()             { DebugFlag="TRUE"; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function errorExit()            { EXITCODE="$1" ; shift; echo "ERROR $*" 1>&2 ; exit "$EXITCODE"; }

function pkgName() {
  echo $(echo $appDirName | xargs dirname | xargs basename | sed 's/\.pkg$//')
}

function installPkg() {
  echo Installing pkg $(pkgName)
  : # TODO

}

function reinstallPkg {
  echo Reinstalling pkg $(pkgName)
  : # TODO
}

function statusPkg() {
  : # TODO
}

function uninstallPkg {
  echo Uninstalling pkg $(pkgName)
  : # TODO
}

function main() {
  declare -r appDirName="$(cd "$(dirname "$0")" ; pwd)"
  [ -z "$1" ] && errorExit 129 command not specified
  [ "$1" = '-D' -o "$1" = '--debug' ] && debugSet && debug enabled && shift
  res=0
  command="$1"
  case "$command" in
    reinstall)
      reinstallPkg; res=$?
      ;;
    install)
      installPkg; res=$?
      ;;
    status)
      statusPkg; res=$?
      ;;
    version)
      echo template:0.0.1   # TODO
      exit 0
      ;;
    uninstall)
      uninstallPkg; res=$?
      ;;
    *) errorExit 9 'command mode not found, currently supported: install, reinstall, status, version. Supplied was: ' $command
      ;;
  esac
  exit $res
}


main "$@"

# EOF
