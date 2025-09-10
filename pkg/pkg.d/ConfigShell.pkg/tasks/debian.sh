#!/usr/bin/env -S bash --norc --noprofile
# shellcheck disable=SC2012

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
    /bin/ls -l "$1" | awk '{ print $3 }'; return 0
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

function deleteSystemdTimer() {
  debug deleting systemd timer,... for configshell upgrades...

  local err=0
  local -r localbin="/usr/local/bin/configshell-upgrade.sh"
  [ -f  "$localbin" ] && { debug4 deleting "$localbin" ; /bin/rm -f "$localbin" ; res=$? ; }
  [ "$res" -ne 0 ] && error error deleting "$localbin" with code "$res", continuing && err=2
  
  systemctl disable --now configshell-upgrade.timer

  for file in /etc/systemd/system/configshell* ; do
    if [ -f "$file" ] ; then 
      debug4 deleting file "$file"
      /bin/rm -f "$file" ; res=$?
      [ "$res" -ne 0 ] && error error deleting "$file" with code "$res", continuing && err=3
    fi
  done
  return "$err"
}

function deleteConfigShell() {
  debug deleting /opt/ConfigShell
  if [ -d /opt/ConfigShell/. ] ; then 
    debug4 /opt/ConfigShell found, actually removing it
    rm -fr /opt/ConfigShell ; res=$?
    [ "$res" -ne 0 ] && error error deleting /opt/ConfigShell, error code "$res", continuing
  fi
}

function deleteConfigShellUserGroup() {
  userdel configshell &>/dev/null ; res=$? # 6 :- user does not exist
  debug delete user configshell returned exit code $res
  [ $res -ne 0 ] && [ $res -ne 6 ] && errorExit 90 error deleting user configshell with exit code $res
  groupdel configshell &>/dev/null ; res=$? # 6 :- group does not exist
  [ $res -ne 0 ] && [ $res -ne 6 ] && errorExit 91 error deleting group configshell with exit code $res
  return 0
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
  echo Installing "$(pkgName)"
  [ ! -d /opt/Configshell/. ] && installConfigShell && return $?
  user=$(ownerFile /opt/ConfigShell/bin )
  [ "$user" != configshell ] && echo ConfigShell is not installed as part of the system using the user configshell. &&
     echo Consider a reinstall? && return 0
}

function reinstallPkg {
  echo Reinstalling "$(pkgName)"
  uninstallPkg
  installPkg
}

function statusPkg() {
  [ -d /opt/ConfigShell/bin ] && echo ConfigShell found && exit 0
  echo NOT FOUND ConfigShell ; exit 1
}

function uninstallPkg {
  echo Uninstalling "$(pkgName)"
  deleteSystemdTimer ; debug deleteSystemdTimer result is $?
  deleteConfigShell ; debug deleteConfigShell result is $?
  deleteConfigShellUserGroup ; debug deleteConfigShellUserGroup result is $?
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
    status) statusPkg # no return
      ;;
    version) echo template:0.0.1 ; exit 0   # TODO
      ;;
    uninstall) uninstallPkg; res=$?
      ;;
    load) return 0  # allow loading of these functions into a bash shell for further testing
      # No other practical use-case is known for this mode.
      ;;
    *) errorExit 9 'command mode not found, currently supported: install, reinstall, status, version, load. Supplied was: ' "$mode"
      ;;
  esac
  exit $res
}


main "$@"

# EOF
