#!/usr/bin/env -S bash --norc --noprofile

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



# loadLib loads the ConfigShell library with functions such as reverse, debug, error, warning, errorExit
function loadLib() {
	########################################################################################
	# ConfigShell lib 1.1 (codebase 1.0.0)
  # 	bashLib="/opt/ConfigShell/lib/bashlib.sh" changing the default path to be relative to the binary
	bashLib="$appDir/../lib/bashlib.sh"
	[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
	# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
	source "$bashLib"
	unset bashLib
}



# continueIfRoot aborts execution if the current effective user is not root 
function continueIfRoot() {
  if [ "$EUID" -ne 0 ]; then
    errorExit 1 "Running as root is required for many installation steps, stopping execution. Please execute it again as root."
  fi
}


# checkpath installed|uninstalled|error errorCode
#   - create the /etc/configshell.pkg/<arg1> if not existing
#   - if it cannot be created, exit the execution with errorCode
#   - the environment variable CONFIGSHELL_PKG_PATH_LOG can be used to overwrite the default path for logging
#   - EXIT 17, 18, 19, $2
function checkpath() {
  [ $# -ne 2 ] && errorExit 19 checkpath is supposed to be called with 2 args and was called with $# args: $*
  [[ "$1" =~ ^(installed|uninstalled|error)$ ]] || errorExit 18 undefined 1st argument is $1
  [[ "$2" =~ ^[0-9]+$ ]] || errorExit 17 exit-code does not only consist of integers....
  [ ! -d $prePath/"$1" ] && sudo mkdir -p $prePath/"$1" 
  [ ! -d $prePath/"$1" ] && errorExit $2 cannot create $prePath/"$1"
}



# recordInstallation records a successful installation
# Only one or no file shall exist for every pkg, either in installed, error, or uninstalled.
# The no file case might exist if the operating system is not supported. Perhaps, this will
# be handled later as an error or a 4th case.
function recordInstallation() {
  checkpath installed 10
  declare -r prePath=${CONFIGSHELL_PKG_PATH_LOG:-/etc/configshell.pkg}
  _date="$(date --utc '+%y%m%d_%H:%M')"
  echo $_date:: $1  | sudo tee /etc/configshell.pkg/installed/$1.$_date # dpkg -l $1 | grep ^ii) 
  find /etc/configshell.pkg/error/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/uninstalled/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
}



# for each pkg, only one entry, here: uninstalled
function recordError() {
  checkpath error 11
  _date="$(date --utc '+%y%m%d_%H:%M')"
  echo $_date::$1  | sudo tee /etc/configshell.pkg/error/$1.$_date
  find /etc/configshell.pkg/installed/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/uninstalled/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
}



# for each pkg, only one entry, here: uninstalled
function recordUninstallation() {
  checkpath uninstalled 12
  _date="$(date --utc '+%y%m%d_%H:%M')"
  echo $_date::$1  | sudo tee /etc/configshell.pkg/uninstalled/$1.$_date
  find /etc/configshell.pkg/installed/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/error/$1* -exec sudo /bin/rm -f {} \; &>/dev/null
} 



# determineOSClass determines and normalises the OS name that we are running on.
# Machine-specific differences are supposed to be handled in the OS-specific pkg-installation scripts.
# A special OS like all has not been implemented as we expect that thoughts are required for any operating
# system if the package is applicable.
# This function is supposed to be extended for more operating systems.
function determineOSClass() {
  which lsb_release &> /dev/null && _release="$(lsb_release -i | grep -i distributor\ id | awk '{ print $NF }')"
  if [ "$_release" = "Debian" ] || [ "$_release" = "Kali" ] ; then
    declare -gr release=debian  
  elif [ "$_release" = "Ubuntu" ] ; then
    declare -gr release=ubuntu  # Ubuntu is not considered to be Debian, as snapd might have to be removed,...
  elif [ "$_release" = "Fedora" ] ; then
    declare -gr release=fedora
  elif [ "$_release" = "Redhat" ] || [ "$_release" = "AlmaLinux" ]  ; then 
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



# processPackage executes for each package and checks minimal package consistency
# SYNOPSIS: processPackage <app> <mode> 
# EXIT 70
function processPackage() {
  local app="$1"
  local mode="$2"
  [ -z "$app" ] || [ -z "$mode" ] && errorExit 70 wrong call to processPkg with arguments $*
  debug working on package $app
  # for every pkg, error if not tasks directory
  [ ! -d "${app}/tasks/" ] && error "${app}/tasks/" not existing, not a configshell pkg, skipping && continue
  # skip if no support for the OS. The OS name is unified in the function determineOSClass in this file
  [ ! -f "${app}/tasks/$osName.sh" ] && error "${app}/tasks/$osName.sh" not found, no support for this OS, skipping && return
  debug installing...
  bash "${app}/tasks/$osName.sh" $mode ; res=$?
  processResult $app $mode $res
}



# EXIT 0, 3, 9
function main() {
  appDir="$(cd $(dirname "$0") ; pwd )"
  appName="$(basename "$0")"
  appBaseName="$(basename "$0" .sh)"
  loadLib         # EXIT 127

  declare -r appVersion='0.0.6'   # required for -V and --version check

  [ "$1" = -D ] || [ "$1" = --debug ] && { debugSet ; debug enabling debug mode ; shift ; }
  [ "$1" = -V ] || [ "$1" = --version ] && { echo $appVersion; exit 0 ; }

  continueIfRoot  # EXIT 1

  enabledPkgDir="${CONFIGSHELL_PKG_DIR:-${appDir}/enabled-pkg.d}"
  osName="$(determineOSClass)"
  debug $osName detected as the operating system
  declare -r prePath=${CONFIGSHELL_PKG_PATH_LOG:-/etc/configshell.pkg}
  [ ! -d "$enabledPkgDir/." ] && errorExit 3 $enabledPkgDir/. not found
     
  if [ -z "$1" ] ; then
    command="status"
  else
    command="$1"
  fi
  case "$command" in
    reinstall) : # reinstall the pkg, even if bits are found before
      ;;
    install) :  # does not overwrite existing installations and changed configurations
      ;;
    uinstall) : # ...
      ;;
    status) : # ... output if installed
      ;;
    version) :
      echo $appVersion
      exit 0
      ;;
    *) :
      errorExit 9 'command mode not found, currently supported: install, reinstall, status, version'
      ;;
  esac
  debug command mode is $command
  shift
  
  if [ -n "$*" ] ; then 
   for app in $enabledPkgDir/$* ; do
      processPackage $app $command
    done
  else
    # check all prerequesites of all packages
    debug running pre checks for:
    find -L $enabledPkgDir -name $osName.pre.sh -print0 | while IFS= read -r -d '' prePkg; do
      debug executing pre-check file $prePkg ...
      bash "$prePkg" || { echo ERROR script $prePkg failed ; exit 2 ; } 
    done ; res=$?
    [ $res -ne 0 ] && errorExit 2 "prerequisite does not hold for a pkg"
    for app in $enabledPkgDir/* ; do 
      echo would start processPackage $app $command
    done
  fi
  # run optional cleanup tasks
  find -L $enabledPkgDir -name $osName.post.sh -print0 | while IFS= read -r -d '' postPkg; do
      debug executing cleanup file $postPkg ...
      bash "$postPkg"
  done
}
 

main "$@"


# EOF

