#!/usr/bin/env bash

function err() {
  1>&2 echo "$@"
}

# EXIT 10
# EXIT 11
# EXIT 12
# EXIT 13
# EXIT 14
function startContainer() {
  POSTGRESQL_CONTAINER_LABEL="$1"
  CONTAINER_VOLUME="$2"
  shift
  shift

  [ ! -r db-connect.pws ] && errorExit 10 'ERROR_USAGE:cannot find db-connect.pws'
  [ ! -L db-connect.pws ] && errorExit 11 'ERROR_USAGE:db-connect.pws is supposed to be an s-link, by convention to db-connect.pw'
  source db-connect.pws
  [ -z "$localadm_USER" ] && errorExit 12 'ERROR_USAGE:cannot find localadm user'
  [ -z "$localadm_PW" ] && errorExit 13 'ERROR_USAGE:cannot find password for localadm'

  # no container can be invoked by setting export ENV_CONTAINER_VOLUME=false
  if [ "$CONTAINER_VOLUME" != 'false' ]; then
    err Using a persistent volume "$CONTAINER_VOLUME"
  else
    CONTAINER_VOLUME=
    err Not using a volume for persistent data storage.
  fi

  # if we are on M1, we have to specify the architecture. An amd64 container started, but postgres was not answering.
  # [ "$(uname -m)" = 'arm64' ] && which podman && arch='--arch arm64'
  arch="${PSQL_CONTAINER_ARCHITECURE:---platform linux/arm64}"

  if [ -n "$CONTAINER_VOLUME" ]; then
    $DRY container.sh volume create "$CONTAINER_VOLUME" && res=$?
    [ "$res" -ne 0 ] && errorExit 14 'ERROR_INTERNAL:creating the container volume'
    $DRY container.sh run -d --name $POSTGRESQL_CONTAINER_LABEL $arch -p 5432:5432 --volume "$CONTAINER_VOLUME":"/var/lib/postgresql/data" -e POSTGRES_PASSWORD=$localadm_PW -e "POSTGRES_USER=$localadm_USER" -e "POSTGRES_DB=$localadm_DB" -d  "$@" "${PSQL_IMAGE_NAME:-postgres}"
  else # same without volume
    $DRY container.sh run -d --name $POSTGRESQL_CONTAINER_LABEL $arch -p 5432:5432 -e POSTGRES_PASSWORD=$localadm_PW -e "POSTGRES_USER=$localadm_USER" -e "POSTGRES_DB=$localadm_DB" -d "$@" "${PSQL_IMAGE_NAME:-postgres}"
  fi
}

#  EXIT 0
#  EXIT 1
#  EXIT 2
#  EXIT 3
#  EXIT 4
#  EXIT 5
function main() {
  #########################################################################################
  # ConfigShell lib 1.1 (codebase 1.0.0)
  bashLib="/opt/ConfigShell/lib/bashlib.sh"
  [ ! -f "$bashLib" ] && echo 1>&2 "bash-library $bashLib not found" && exit 127
  # shellcheck source=/opt/ConfigShell/lib/bashlib.sh
  source "$bashLib"
  unset bashLib
  #########################################################################################

  exitIfBinariesNotFound container.sh

  # environment variables to override the labels for the containes
  POSTGRESQL_CONTAINER_LABEL="${PSQL_CONTAINER_NAME:-psql0}"
  CONTAINER_VOLUME="${PSQL_CONTAINER_VOLUME:-psql0}" # set again for delete command
  DRY=
  if [ "$1" = '-n' ]; then
    err DRY run mode
    DRY=echo
    shift
  else
    DRY=
  fi

  container.sh ps > /dev/null ; res=$?
  [ $res -ne 0 ] && errorExit 5 Container environment does not seem to be started or user is not in the required group.

  local -r _options='init|start|stop|delete|status|version|help'
  case "$1" in
  init)
    shift
    startContainer "$POSTGRESQL_CONTAINER_LABEL" "$CONTAINER_VOLUME" "$@"
    ;;
  start)
    shift
    container.sh start "$@" "$POSTGRESQL_CONTAINER_LABEL"
    ;;
  stop)
    shift
    container.sh stop "$@" "$POSTGRESQL_CONTAINER_LABEL"
    ;;
  delete)
    container.sh container rm "$POSTGRESQL_CONTAINER_LABEL"
    container.sh volume rm "$CONTAINER_VOLUME"
    ;;
  status)
    shift
    local -r output=$(container.sh  ps -q  --filter name="${POSTGRESQL_CONTAINER_LABEL}" "$@")
    [ -z "$output" ] && exit 1
    echo "$output" ; exit 0
    ;;
  help)
    err $(basename $0) ${_options}
    err
    err SUMMARY
    err Script to create a local PSQL DB as a container with a persistent volume,
    err
    err "OPTIONAL EXTERNAL ENVIRONMENT VARIABLES:"
    err "PSQL_CONTAINER_NAME:-psql0"
    err "PSQL_CONTAINER_VOLUME:-psql0"
    err "PSQL_IMAGE_NAME:-postgres"
    err "PSQL_CONTAINER_ARCHITECURE:-\'--platform linux/arm64\'"
    exit 2
    ;;
  version)
    err 1.2.0
    exit 3
    ;;
  *)
    errorExit 4 'ERROR_UNKNOWN_COMMAND:usage:' ${_options}
    ;;
  esac
}

set -u
main "$@"

# EOF
