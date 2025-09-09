#!/usr/bin/env -S bash --norc --noprofile

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
    [ ! -e "$1" ] && errorExit 252 in ownerfile file not found $1
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
  echo $(echo $appDirName | xargs dirname | xargs basename | sed 's/\.pkg$//')
}

###########################################################################################3

# EXIT 40, 41, 42, 43, 44, 45
function createSystemdTimer() {
  echo Setting up systemd
  [ ! -d /etc/systemd/system ] && errorExit 40 cannot find dir /etc/systemd/system
  [ ! -d /opt/ConfigShell/share/ConfigShellUpgradeBySystemd/ ] && errorExit 41 cannot find dir /opt/ConfigShell/share/ConfigShellUpgradeBySystemd/
  # no -a to avoid -go group+owner
  sudo rsync -pt --copy-links /opt/ConfigShell/share/ConfigShellUpgradeBySystemd/configshell-upgrade.sh /usr/local/bin || \
    errorExit 44 error rsyncing confighsell-upgrade.sh
  sudo rsync -rlptD --copy-links /opt/ConfigShell/share/ConfigShellUpgradeBySystemd/configshell-upgrade.* /etc/systemd/system || \
    errorExit 42 error rsyncing systemd unit files
  sudo chown root:root /etc/systemd/system/configshell-upgrade.* || errorExit 43 cannot normalise ownership of /etc/systemd/system/configshell..
  sudo systemctl daemon-reload
  sudo systemctl enable --now configshell-upgrade.timer || errorExit 45 cannot enable + start configshell-upgrade.timer
  sudo systemctl status configshell-upgrade.timer
}

# ConfigShell not found, install it. 
# EXIt 20, 22, 23
function installConfigShell() { 
  mkdir /opt/ConfigShell || errorExit 20 cannot create /opt/ConfigShell
  useradd configshell 
  groupadd configshell
  git clone --depth 1 -b master https://github.com/engelch/ConfigShell /opt/ConfigShell || errorExit 22 cannot clone ConfigShell
  createSystemdTimer || errorExit 23 error while creating systemd timer
}

function installPkg() {
  echo Installing pkg $(pkgName)
  [ ! -d /opt/Configshell/. ] && installConfigShell && return $?
  user=$(ownerFile /opt/ConfigShell/bin )
  [ "$user" != configshell ] && echo ConfigShell is not installed as part of the system using the user configshell. &&
     echo Consider a reinstall? && return 0
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

# pkg also supports <<osName>>.pre.sh and <<osName>>.post.sh scripts.
#
#  They are run before or after all enabled packages were or will be (re-)installed.
#
function main() {
  declare -r appDirName="$(cd "$(dirname "$0")" ; pwd)"
  [ -z "$1" ] && errorExit 129 command not specified
  [ "$1" = '-D' -o "$1" = '--debug' ] && debugSet && debug enabled && shift
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
    *) errorExit 9 'command mode not found, currently supported: install, reinstall, status, version. Supplied was: ' $command
      ;;
  esac
  exit $res
}


main "$@"

# EOF
