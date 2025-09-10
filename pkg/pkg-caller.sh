#!/usr/bin/env -S bash --norc --noprofile
# shellcheck disable=SC2329,SC2012,SC2048,SC2155

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

##########################################################################################################3

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
  [ $# -ne 2 ] && errorExit 19 checkpath is supposed to be called with 2 args and was called with $# args: "$*"
  [[ "$1" =~ ^(installed|uninstalled|error)$ ]] || errorExit 18 undefined 1st argument is "$1"
  [[ "$2" =~ ^[0-9]+$ ]] || errorExit 17 exit-code does not only consist of integers....
  [ ! -d "$prePath/$1" ] && sudo mkdir -p "$prePath/$1" 
  [ ! -d "$prePath/$1" ] && errorExit "$2" cannot create "$prePath/$1"
}



# recordInstallation records a successful installation
# Only one or no file shall exist for every pkg, either in installed, error, or uninstalled.
# The no file case might exist if the operating system is not supported. Perhaps, this will
# be handled later as an error or a 4th case.
function recordInstallation() {
  checkpath installed 10
  declare -r prePath=${CONFIGSHELL_PKG_PATH_LOG:-/etc/configshell.pkg}
  pkgName="$(echo "$1" | sed -E 's/^[0-9]+-//')"
  _date="$(date --utc '+%y%m%d_%H:%M')"
  find /etc/configshell.pkg/ -name "$1*" -exec /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/ -name "$pkgName*" -exec /bin/rm -f {} \; &>/dev/null
  echo "$pkgName::$_date"  | sudo tee "/etc/configshell.pkg/installed/$pkgName.$_date"
}



# for each pkg, only one entry, here: uninstalled
function recordError() {
  checkpath error 11
  pkgName="$(echo "$1" | sed -E 's/^[0-9]+-//')"
  _date="$(date --utc '+%y%m%d_%H:%M')"
  find /etc/configshell.pkg/ -name "$1*" -exec /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/ -name "$pkgName*" -exec /bin/rm -f {} \; &>/dev/null
  echo "$pkgName::$_date"  | sudo tee /etc/configshell.pkg/error/"$pkgName.$_date"
}



# for each pkg, only one entry, here: uninstalled
function recordUninstallation() {
  checkpath uninstalled 12
  pkgName="$(echo "$1" | sed -E 's/^[0-9]+-//')"
  _date="$(date --utc '+%y%m%d_%H:%M')"
  debug recordUninstallation called with "$1"
  find /etc/configshell.pkg/ -name "$pkgName*" -exec /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/ -name "$1*" -exec /bin/rm -f {} \; &>/dev/null
  echo "$pkgName::$_date" | tee "/etc/configshell.pkg/uninstalled/$pkgName.$_date"
} 



# determineOSClass determines and normalises the OS name that we are running on.
# Machine-specific differences are supposed to be handled in the OS-specific pkg-installation scripts.
# A special OS like all has not been implemented as we expect that thoughts are required for any operating
# system if the package is applicable.
# This function is supposed to be extended for more operating systems.
# supported output:
#   darwin
#   debian
#   ubuntu (might be different as snap must be handled)
#   redhat
#   fedora (dnf vs yum)
function determineOSClass() {
  if lsb_release &> /dev/null ; then
    _release="$(lsb_release -i | grep -i distributor\ id | awk '{ print $NF }' | tr '[:upper:]' '[:lower:]')" 
  elif [ -f /etc/os-release ] ; then
    _release="$(grep '^ID=' /etc/os-release | sed s/ID=// | sed 's/\"//g' | tr '[:upper:]' '[:lower:]')" 
  elif [ "$(uname)" = "Darwin" ] ; then
    declare -gr release=darwin && echo $release && return 0
  else
    errorExit 21 cannot determine the OS
  fi
  # normalise the returned name
  if [ "$_release" = "debian" ] || [ "$_release" = "kali" ] ; then
    declare -gr release=debian  
  elif [ "$_release" = "ubuntu" ] ; then
    declare -gr release=ubuntu  # Ubuntu is not considered to be Debian, as snapd might have to be removed,...
  elif [ "$_release" = "fedora" ] ; then
    declare -gr release=fedora
  elif [ "$_release" = "redhat" ] || [ "$_release" = "almalinux" ]  ; then 
    declare -gr release=redhat
  else
    [ -z "$release" ] && errorExit 20 cannot determine the OS
  fi
  echo "$release"
}



# processResult $app $mode $result
#   Write the execution for the given app into either /etc/configshell.pkg/{installed,uninstalled,error}.
#   Make sure that entries for the given app exist only in one of these directories.
function processResult() {
  [ $# -ne 3 ] && errorExit 30 processResult should always be called with 3 arguments, passed as $# arguments was: "$*"
  app="$(basename "$1")"
  mode="$2"
  result="$3"
  debug processResult called with "$app $mode $result"
  case "$mode" in
    # uninstall must be defined before *install. Only the 1st matching case is executed.
    uninstall) debug uninstall processResult app "$app" mode "$mode" result "$result"
      [ "$result" -eq 0 ] && recordUninstallation "$app"
      [ "$result" -ne 0 ] && recordError "$app" "$result"
      ;;
    *install) debug install processResult app "$app" mode "$mode" result "$result"
      [ "$result" -eq 0 ] && recordInstallation "$app"
      [ "$result" -ne 0 ] && recordError "$app" "$result"
      ;;
    status) : # no action
      ;;
    *) errorExit 31 unknown mode to processResult: "$mode"
      ;;
  esac
  return 0
}



function osSupportForOSClass() {
  echo scripts to be executed in the following sequence ...
  local result=0
  find -L "$enabledPkgDir" -mindepth 1 -maxdepth 1 -type d -print | sort | sed -e 's/^.*enabled-pkg.d\//    /'

  error=0
  for pkg in $(find -L "$enabledPkgDir" -mindepth 1 -maxdepth 1 -type d -print | sort) ; do
    if [ ! -f "$pkg/tasks/$osName.sh" ] ; then
      error=1
      local pkgShortName="$(echo "$pkg" | sed -e 's/^.*enabled-pkg.d\///')"
      echo "Error: package $pkgShortName does not support the operating system $osName"
    fi
  done
  [ "$error" -ne 0 ] && errorExit 80 not all packages support the os class "$osName"
}



# processPackage executes for each package and checks minimal package consistency
# SYNOPSIS: processPackage <app> <mode> 
# EXIT 70
function processPackage() {
  local app="$1"
  local mode="$2"
  [ -z "$app" ] || [ -z "$mode" ] && errorExit 70 wrong call to processPkg with arguments "$*"
  debug working on package "$app"
  # for every pkg, error if not tasks directory
  [ ! -d "${app}/tasks/" ] && error "${app}/tasks/" not existing, not a configshell pkg, skipping && return
  # skip if no support for the OS. The OS name is unified in the function determineOSClass in this file
  [ ! -f "${app}/tasks/$osName.sh" ] && errorExit 71 "${app}/tasks/$osName.sh" not found, no support for this OS
  debug installing...
  bash "${app}/tasks/$osName.sh" $passDebug "$mode" ; res=$?
  processResult "$app" "$mode" "$res"
}



# EXIT 0, 3, 9
function main() {
  appDir="$(cd "$(dirname "$0")" || errorExit 128 error determining appDir; pwd )"

  declare -r appVersion='0.0.10'   # required for -V and --version check

  passDebug=

  [ "$1" = -D ] || [ "$1" = --debug ] && { debugSet ; passDebug='-D' ; debug enabling debug mode ; shift ; }
  [ "$1" = -V ] || [ "$1" = --version ] && { echo "$appVersion"; exit 0 ; }

  continueIfRoot  # EXIT 1

  enabledPkgDir="${CONFIGSHELL_PKG_DIR:-${appDir}/enabled-pkg.d}"
  osName="$(determineOSClass)"
  debug "$osName" detected as the operating system
  declare -r prePath=${CONFIGSHELL_PKG_PATH_LOG:-/etc/configshell.pkg}
  [ ! -d "$enabledPkgDir/." ] && errorExit 3 "$enabledPkgDir/." not found
     
  if [ -z "$1" ] ; then
    command="status"
  else
    command="$1"
  fi
  case "$command" in
    reinstall|install|uninstall|status) : # execution below using processPackage ...
      ;;
    version) :
      echo $appVersion
      exit 0
      ;;
    os)
      debug os called to get the name of the operating system determined
      determineOSClass; exit $?
      ;;
    list|list-enabled|enabled-pkg)
      /bin/ls -1 "$enabledPkgDir/"
      exit $?
      ;;
    list-available|available-pkg)
      /bin/ls -1 "${appDir}/pkg.d/"
      exit $?
      ;;
    *) :
      errorExit 9 'command mode not found, currently supported: install, reinstall, status, version, list-enabled, list-available, os'
      ;;
  esac
  debug command mode is "$command"
  shift
  
  osSupportForOSClass

  if [ -n "$*" ] ; then 
   for app in $enabledPkgDir/$* ; do
      debug starting explicit work calling processPackage "$app" "$command"
      processPackage "$app" "$command"; res=$? ; debug result from processPackage was "$res"
      [ "$res" -ne 0 ] && errorExit 9 error running processPackage "$app" "$command" with res "$res"
    done
  else
    # check all prerequesites of all packages, before actually running the normal package modes
    # debug running pre checks for:
    # find -L "$enabledPkgDir" -name "$osName.pre.sh" -print0 | while IFS= read -r -d '' prePkg; do
      # debug executing pre-check file "$prePkg" ...
      # bash "$prePkg" ||  errorExit 3 script "$prePkg" failed
    # done ; res=$?
    # [ "$res" -ne 0 ] && errorExit 2 "prerequisite does not hold for a pkg"
    for app in "$enabledPkgDir/"* ; do 
      debug starting processPackage "$app" "$command"
      processPackage "$app" "$command" ; res=$? ; debug result calling processPackage "$app" "$command" was  "$res"
      [ "$res" -ne 0 ] && errorExit 9 error running processPackage "$app" "$command" with res "$res"
    done
  fi

  # run optional cleanup tasks, after all installations,... are done
  # find -L $enabledPkgDir -name $osName.post.sh -print0 | while IFS= read -r -d '' postPkg; do
      # debug executing cleanup file $postPkg ...
      # bash "$postPkg"
  # done
}
 

main "$@"


# EOF

