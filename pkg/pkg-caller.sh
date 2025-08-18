#!/usr/bin/env bash

#########################################################################################
# pkg installer as an alternative to ansible
#  - it does not require python, no specific version, no problems with dependencies and
#    the famous requirements.txt.
#  - it only requires bash UNIX default tools
#    - it tries to stay POSIX compatible
#    - tools required: bash (version ≥ 3), sudo, mkdir, grep, sed, awk, date -u, tee, find, tr, which
#  - it requires execution from the host of installation
#  - sudo must be enabled for the user
#  - it logs activity in /etc/configshell.pkg
#     - an activity is either logged in installed, error, or uninstalled
#     - multiple entries can exist for installed, error, or uninstalled, but all entries
#       are either in installed, error, or uninstalled ⇒ you do not have to check which
#       is the last entry to see if a pkg was installed, uninstalled, or ended in an error
#  - the installation is operating-system dependent

function loadLib() {
	########################################################################################
	# ConfigShell lib 1.1 (codebase 1.0.0)
	bashLib="/opt/ConfigShell/lib/bashlib.sh"
	[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
	# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
	source "$bashLib"
	unset bashLib
}

# checkpath installed|uninstalled|error errorCode
#   - create the /etc/configshell.pkg/<arg1> if not existing
#   - if it cannot be created, exit the execution with errorCode
function checkpath() {
  declare -r prePath=/etc/configshell.pkg
  [ $# -ne 2 ] && errorExit 19 checkpath is supposed to be called with 2 args and was called with $# args: $*
  [[ "$1" =~ ^(installed|uninstalled|error)$ ]] || errorExit 18 undefined 1st argument is $1
  [[ "$2" =~ ^[0-9]+$ ]] || errorExit 17 exit-code does not only consist of integers....
  [ ! -d $prePath/"$1" ] && sudo mkdir -p $prePath/"$1" 
  [ ! -d $prePath/"$1" ] && errorExit $2 cannot create $prePath/"$1"
}

function recordInstallation() {
  checkpath installed 10
  _date="$(date --utc '+%y%m%d_%H:%M')"
  echo $_date:: $1  | sudo tee /etc/configshell.pkg/installed/$1.$_date # dpkg -l $1 | grep ^ii) 
  find /etc/configshell.pkg/error/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/uninstalled/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
}

function recordError() {
  checkpath error 11
  _date="$(date --utc '+%y%m%d_%H:%M')"
  echo $_date::$1  | sudo tee /etc/configshell.pkg/error/$1.$_date
  find /etc/configshell.pkg/installed/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/uninstalled/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
}

function recordUninstallation() {
  checkpath uninstalled 12
  _date="$(date --utc '+%y%m%d_%H:%M')"
  echo $_date::$1  | sudo tee /etc/configshell.pkg/uninstalled/$1.$_date
  find /etc/configshell.pkg/installed/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/error/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
} 

function determineOS() {
  which lsb_release &> /dev/null && _release="$(lsb_release -i | grep -i distributor\ id | awk '{ print $NF }')"
  if [ "$_release" = "Debian" ] ; then
    declare -gr release=debian  
  elif [ "$_release" = "Ubuntu" ] ; then
    declare -gr release=ubuntu
  elif [ "$_release" = "Fedora" ] ; then
    declare -gr release=fedora
  elif [ "$_release" = "Redhat" ] ; then 
    declare -gr release=redhat
  else
    [ -z "$release" ] && [ -f /etc/os-release ] && \
       _release="$(grep ID= /etc/os-release | sed s/ID=// |  tr '[:upper:]' '[:lower:]')" 
    [ -n "$_release" ] && declare -gr release="$_release"
    [ -z "$_release"] && [ "$(uname)" = "Darwin" ] && declare -gr release=darwin
  fi
  [ -z "$release" ] && errorExit 20 cannot determine the OS
  echo "$release"
}

# processResult $app $mode $result
#   Write the execution for the given app into either /etc/configshell.pkg/{installed,uninstalled,error}.
#   Make sure that entries for the given app exist only in one of these directories.
function processResult() {
  [ $# -ne 3 ] && errorExit 30 processResult should always be called with 3 arguments, passed as $# arguments was: $*
  app="$(basename "$1")"
  mode="$2"
  result="$3"
  case "$mode" in
    # uninstall must be defined before *install. Only the 1st matching case is executed.
    uninstall) echo uninstall processResult app $app mode $mode result $result
      [ "$result" -eq 0 ] && recordUninstallation $app
      [ "$result" -ne 0 ] && recordError $app $result
      ;;
    *install) echo install processResult app $app mode $mode result $result
      [ "$result" -eq 0 ] && recordInstallation $app
      [ "$result" -ne 0 ] && recordError $app $result
      ;;
    status) : # no action
      echo status called, no action in processResults
      ;;
    *) errorExit 31 unknown mode to processResult: $mode
      ;;
  esac
}

function main() {
  unset release
  loadLib
  appDir="$(dirname "$0")"
  appName="$(basename "$0")"
  appBaseName="$(basename "$0" .sh)"
  enabledPkgDir="${PKGDIR:-${appDir}/enabled-pkg.d}"
  osName="$(determineOS)"
  echo $osName detected as the operating system
  [ ! -d "$enabledPkgDir/." ] && errorExit 3 $enabledPkgDir/. not found
     
  if [ -z "$1" ] ; then
    command="status"
  else
    command="$1"
  fi
  case "$command" in
    force-install) :
      ;;
    install) :
      ;;
    uninstall) :
      ;;
    status) :
      ;;
    version) echo 0.0.3
      exit 0
      ;;
    *) errorExit 9 'command mode not found, currently supported: install, force-install, status, version'
      ;;
  esac
  echo command is $command
  shift
  if [ -n "$*" ] ; then 
    for app in $enabledPkgDir/$* ; do
      [ ! -d "${app}/tasks/" ] && error "${app}/tasks/" not existing, not a configshell pkg, skipping && continue
      [ ! -f "${app}/tasks/$osName.sh" ] && error "${app}/tasks/$osName.sh" not found, no support for this OS, skipping && continue
      bash "${app}/tasks/$osName.sh" $mode ; res=$?
      processResult $app $command $res
    done
  else
    for app in $enabledPkgDir/* ; do 
      [ ! -d "${app}/tasks/" ] && error "${app}/tasks/" not existing, not a configshell pkg, skipping && continue
      [ ! -f "${app}/tasks/$osName.sh" ] && error "${app}/tasks/$osName.sh" not found, no support for this OS, skipping && continue
      bash "${app}/tasks/$osName.sh" $mode ; res=$?
      processResult $app $command $res
    done
  fi
}
 

main "$@"


# EOF

