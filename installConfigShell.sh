#!/usr/bin/env bash
# Copyright Christian Engel 2025 ©
# License: MIT
# Title: configShellInstall.sh
# About: install configshell with in case of 
#   - Linux auto upgrades using systemd
# Quality: script checked for shellcheck



# enable conditional debug
function debugSet()             { DebugFlag="TRUE"; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }



# output to stderr
function err()          { echo "$*" 1>&2; }                 # just write to stderr
function err4()         { echo '   ' "$*" 1>&2; }           # just write to stderr



# errorExit is a helper function with exits with the code supplied as the first
# argument. The other arguments are output to stderr.
# EXIT <<arg1>>
function errorExit() {
   code="$1"
   shift
   echo 1>&2 "$*"
   exit "$code"
}



# Set the CWD for the temporary clone of the ConfigShell directory.
# Exit, if the script cannot change to the directory.
# EXIT 1, 2, 3
function setWorkingDirectory() {
   if [ -d "$HOME/tmp" ] ; then
      cd "$HOME/tmp" || errorExit 1 error changing CWD to "$HOME/tmp"
   else
      # unlikely
      cd || errorExit 2 error changing CWD to "$HOME"
   fi
   [ ! -w . ] && errorExit 3 The current directory "$CWD" does not seem to be writable.
   debug setWorkingDir passed
}



# exit if the current working directory is not supported.
# EXIT 20
function checkForOS() {
   [ "$(uname)" != Linux ] && errorExit 20 OS is "$(uname)" and not supported.
   debug checkForOS passed
}



# checkForApps checks for required application. It stops execution as soon
# as one of the applications are not found.
# EXIT 10
function checkForApps() {
   local app
   for app in git systemctl journalctl ; do
      which "$app" &>/dev/null || errorExit 10 "$app" not found
   done
   debug checkForApps passed
}



# checkforNoPreviousInstallation validates that no artifacts of a previous ConfigShell
# installation are detected which might cause a failure of this installation.
# EXIT 30
function checkforNoPreviousInstallation() {
   [ -d /opt/ConfigShell ] && errorExit 30 Previous ConfigShell installation found
   debug checkforNoPreviousInstallation passed
}



# main starting all other functionality
function main() {
   [ "$1" = '-D' ] || [ "$1" = '--debug' ] && { shift ; debugSet ; debug enabled. ; }
   checkforNoPreviousInstallation
   checkForOS
   checkForApps
   setWorkingDirectory
   echo ready for the next step
}

main "$@"

# EOF
