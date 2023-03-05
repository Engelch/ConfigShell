#!/usr/bin/env bash

function debugSet()             { DebugFlag=TRUE; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debugExecIfDebug()     { [ "$DebugFlag" = TRUE ] && "$*"; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' "$*" 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:            ' "$*" 1>&2 ; return 0; }

function error()        { echo 'ERROR:'"$*" 1>&2;             return 0; }
function error4()       { echo 'ERROR:    '"$*" 1>&2;         return 0; }
function error8()       { echo 'ERROR:        '"$*" 1>&2;     return 0; }
function error12()      { echo 'ERROR:            '"$*" 1>&2; return 0; }

function errorExit()    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }
function exitIfErr()    { a="$1"; b="$2"; shift; shift; [ "$a" -ne 0 ] && errorExit "$b" App returned "$a" "$*"; }

function err()          { echo "$*" 1>&2; }                 # just write to stderr
function err4()         { echo '   ' "$*" 1>&2; }           # just write to stderr
function err8()         { echo '       ' "$*" 1>&2; }       # just write to stderr
function err12()        { echo '           ' "$*" 1>&2; }   # just write to stderr

# --- Existance checks
function exitIfBinariesNotFound()       { for file in "$@"; do [ $(command -v "$file") ] || errorExit 253 binary not found: "$file" ; done }

############################

# setDockerCmd
function setDockerCmd() {
   dockerCmd=
   # Listed in order of ASCENDING preference (podman > docker)
   which docker &>/dev/null && dockerCmd=docker
   which podman &>/dev/null && dockerCmd=podman
   [ -z "$dockerCmd" ] && errorExit 10 no docker command found
   debug docker command is set to "$dockerCmd"
}

# EXIT 15 if no Containerfile/Dockerfile found
function setContainerFile() {
  declare -r Dockerfile="Containerfile Dockerfile"
  IFS=' '
  for _file in $Dockerfile ; do
    debug check for file $_file
    if [ -f "$_file" ] ; then
      dockerfile="$_file"
      debug dockerfile is $dockerfile
      return
    fi
  done
  errorExit 15 Neither Containerfile nor Dockerfile found
}

function buildContainer() {
  for one_file in ${DOCKERFILE}; do
      version=$(version.sh)
      [ -z "$version" ] && errorExit 11 echo could not set version
      cd -
      echo version is $version
      IMAGE_TAG="$version"

      IMAGE_NAME="$(echo "${one_file}" | awk -F'.' '{ print $2; }')"
      IMAGE_URL=${REGISTRY}/${IMAGE_NAME}:$version
      IMAGE_URL_LATEST=${REGISTRY}/${IMAGE_NAME}:latest

      echo "----------------------------------------------"
      echo "Selected runtime: ${EXEC}, architecture: ${IMAGE_ARCHITECTURE}, image: ${IMAGE_URL}"

      $dry_run $EXEC build ${IMAGE_ARCHITECTURE} -t "${IMAGE_URL}" -t "${IMAGE_URL_LATEST}" -f "${one_file}" || {
          echo "ERROR: failed to build image"
          exit 25
      }
  done
}


# --- Default Script Functions
function usage()
{
    err NAME
    err4 "$App"
    err
    err SYNOPSIS
    err4 "$App" '[-D] [-n] ([-t <<targetArchitecture>>]...)'
    err4 "$App" '-h'
    err
    err VERSION
    err4 "$AppVersion"
    err
    err DESCRIPTION
    err4 Build a container with podman if found or else with
    err
    err OPTIONS
    err4 '-D            ::= enable debug output'
    err4 '-n            ::= enable dry-run mode'
    err4 '-t <<arch>>   ::= set the target architecture. The option can be specified multiple times.'
    err4 '-h            ::= show usage message and exit with exit code 1'
}

# EXIT 1 help
# EXIT 2 AppVersion
function parseCLI() {
  dry_run=                # not set by default
  target_architecture=    # not set by default
  while getopts "DVhnt:" options; do         # Loop: Get the next option;
    case "${options}" in                    # TIMES=${OPTARG}
      D)  debugSet ; debug debug enabled
          ;;
      V)  echo $AppVersion ; exit 2
          ;;
      h)  usage ; exit 1
          ;;
      n)  dry_run=echo ; debug dry run mode enabled
          ;;
      t)  # set target architecture
          target_architecture="$target_architecture --arch=${OPTARG}"
          ;;
      *)  err Help with "$_app" -h
          exit 2  # Exit abnormally.
          ;;
    esac
  done
}

function setDefaultArchitecture() {
  arch=$(uname -m)
  [[ "$args" =~ arm ]] && return
  [[ "$args" =~ x86 ]] && arch=amd64
  [ -z "$target_architecture" ] && debug target architecture detected by OS && target_architecture="--arch=$arch"
  [ -n "$target_architecture" ] && debug "target architecture explicitly set"
  debug target_architecture is $target_architecture
}

function setContainerName() {
  if [ $(/bin/ls | grep -c '^_name_.*' ) -eq 1 ] ; then
    containerName=$(/bin/ls | grep '^_name_.*' | sed 's/.*_name_//')
  else
    containerName=$(basename $PWD)
    [ "$containerName" = src ] && containerName=$(dirname $PWD | xargs basename)
  fi
  debug container name is $containerName
}

function buildTags() {
  version=$(version.sh)
  [ -z "$version" ] && errorExit 20 could not determine the version of the image to be built
  debug version tag is "$version"
  date=$(date -u +%y%m%d_%H%M%S)
  debug date tag is "$date"
}

function main() {
    declare -r App=$(basename "${0}")
    # declare -r AppDir=$(dirname "$0")
    # declare -r AbsoluteAppDir=$(cd "$_appDir" || exit 99 ; /bin/pwd)
    declare -r AppVersion="0.9.2"      # use semantic versioning
    parseCLI "$@"
    shift "$(( OPTIND - 1 ))"  # not working inside parseCLI
    # debug args are "$*"
    setDefaultArchitecture    # must be run before parseCLI
    setDockerCmd
    setContainerFile
    setContainerName
    buildTags
    $dry_run $dockerCmd build $target_architecture -t "$containerName:$date" -t "$containerName:$version" -t "$containerName:latest" .
}

main "$@"

# EOF
