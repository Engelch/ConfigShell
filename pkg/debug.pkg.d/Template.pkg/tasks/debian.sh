#!/usr/bin/env -S bash --norc --noprofile
# shellcheck disable=SC2012
#
export DebugFlag=${DebugFlag:-FALSE}
function debugSet()             { DebugFlag="TRUE"; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function errorExit()            { EXITCODE="$1" ; shift; echo "ERROR $*" 1>&2 ; exit "$EXITCODE"; }

# --- Existance checks
function exitIfBinariesNotFound()       { for file in "$@"; do command -v "$file" &>/dev/null || errorExit 253 binary not found: "$file"; done }
function exitIfPlainFilesNotExisting()  { for file in "$@"; do [ ! -f "$file" ] && errorExit 254 'plain file not found:'"$file" 1>&2; done }
function exitIfFilesNotExisting()       { for file in "$@"; do [ ! -e "$file" ] && errorExit 255 'file not found:'"$file" 1>&2; done }
function exitIfDirsNotExisting()        { for dir in  "$@"; do [ ! -d "$dir"  ] && errorExit 252 "$APP:ERROR:directory not found:$dir"; done }

# ownerFile returns the ownername as a string
function ownerFile() {
    [ ! -e "$1" ] && errorExit 252 in ownerfile file not found "$1"
    ls -l "$1" | awk '{ print $3 }'; return 0
}

# lineExisting
# EXIT 100, 101, 102
function lineExisting() {
  [ $# != 2 ]   && errorExit 100 "wrong call to lineExisting, args are $#, expected:2"
  [ ! -e "$2" ] && errorExit 101 "file $2 not existing"
  [ ! -r "$2" ] && errorExit 102 "file $2 not readable"
  # echo output is "$(grep -Ec "$1" "$2")"
  [ "$(grep -Ec "$1" "$2")" -gt 0 ] && return 0
  return 1
}


function pkgName() {
  echo "$appDirName" | xargs dirname | xargs basename | sed 's/\.pkg$//'
}
  

function installPkg() {
  echo Installing pkg "$(pkgName)"
  : # TODO

}

function reinstallPkg {
  echo Reinstalling pkg "$(pkgName)"
  : # TODO
}

function statusPkg() {
  : # TODO
}

function uninstallPkg {
  echo Uninstalling pkg "$(pkgName)"
  : # TODO
}

# pkg also supports <<osName>>.pre.sh and <<osName>>.post.sh scripts.
#
#  They are run before or after all enabled packages were or will be (re-)installed.
#
function main() {
  declare -r appDirName="$(cd "$(dirname "$0")" || errorExit 128 cannot cd to dir; pwd)"
  [ -z "$1" ] && errorExit 129 command not specified
  [ "$1" = '-D' ] || [ "$1" = '--debug' ] && debugSet && debug enabled && shift

  res=0
  mode="$1"
  case "$mode" in
    reinstall) reinstallPkg; res=$?
      ;;
    install) installPkg; res=$?
      ;;
    status) statusPkg; res=$?
      ;;
    version) echo template:0.0.1 ; exit 0   # TODO
      ;;
    uninstall) uninstallPkg; res=$?
      ;;
    load) return 0  # allow loading of these functions into a bash shell for further testing
      ;;
    *) errorExit 9 'command mode not found, currently supported: install, reinstall, status, version. Supplied was: ' "$mode"
      ;;
  esac
  exit $res
}


main "$@"

# EOF
