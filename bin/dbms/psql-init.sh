#!/usr/bin/env bash
set -u

declare -g -r _options='init|s|start|e|stop|delete|status|version|h|-h|help|--help|name=...|volume=...|arch=...|image=...|port=...'

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
  PSQL_PORT="${PSQL_PORT:-$localadm_PORT}"

  if [ -n "$CONTAINER_VOLUME" ]; then
    $DRY container.sh volume create "$CONTAINER_VOLUME" && res=$?
    [ "$res" -ne 0 ] && errorExit 14 'ERROR_INTERNAL:creating the container volume'
    $DRY container.sh run -d --name $POSTGRESQL_CONTAINER_LABEL ${PSQL_CONTAINER_ARCHITECTURE:-}  -p $PSQL_PORT:5432 --volume "$CONTAINER_VOLUME":"/var/lib/postgresql/data" -e POSTGRES_PASSWORD=$localadm_PW -e "POSTGRES_USER=$localadm_USER" -e "POSTGRES_DB=$localadm_DB" -d  "$@" "${PSQL_IMAGE_NAME:-postgres}"
  else # same without volume
    $DRY container.sh run -d --name $POSTGRESQL_CONTAINER_LABEL ${PSQL_CONTAINER_ARCHITECTURE:-} -p $PSQL_PORT:5432 -e POSTGRES_PASSWORD=$localadm_PW -e "POSTGRES_USER=$localadm_USER" -e "POSTGRES_DB=$localadm_DB" -d "$@" "${PSQL_IMAGE_NAME:-postgres}"
  fi
}

function helpExit() {
    err $(basename $0) ${_options}
    err
    err SUMMARY
    err Script to create a local PSQL DB as a container with a persistent volume.
    err
    err The script requires a db-connect.pws file which defines the user localadm as shown below.
    err db-connect.pws is supposed to be an s-link to a db-connect.pw file. This is verified.
    err The split between pws and pw files allows to easily add pws-files using git add but
    err the pw-file must usually be protected, for example by using git gee.
    err
    err The password and the user are used to set up the super-user of the DBMS. It is common
    err practice that the complete record for the localadm looks like:
    err
    err localadm_DB_TYPE=psql
    err localadm_HOST=127.0.0.1
    err localadm_PORT=5432
    err localadm_USER=postgres...considerUsingAnAlternative
    err localadm_PW=setYourPasswordHere..............
    err localadm_DB=postgres
    err
    err It is not a bad idea to use a different default admin user instead of postgres to make
    err hacking attempts more difficult. Experience shows that such topics should already be
    err addressed at development time. Often, they are to be forgotten in later stages.
    err 
    err "OPTIONAL EXTERNAL ENVIRONMENT VARIABLES or CLI arguments:"
    err name=psql0 default is psql0, or use "PSQL_CONTAINER_NAME=..."
    err volume=psql0 default is psql0, or use "PSQL_CONTAINER_VOLUME=..."
    err image=postgres default is postgres "PSQL_IMAGE_NAME=..."
    err arch='linux/arm64' default is not set, or set it like: "PSQL_CONTAINER_ARCHITECTURE='--platform linux/arm64'"
    err port=nnn default is defined from db-connect.pws, or use "PSQL_PORT=..." to overwrite it.
    exit 2
}

#####################################################################
# main
#  EXIT 0
#  EXIT 1
#  EXIT 2
#  EXIT 3
#  EXIT 4
#  EXIT 5
# EXIT 6 wrong container_label
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
  export POSTGRESQL_CONTAINER_LABEL="${PSQL_CONTAINER_NAME:-psql0}"
  export CONTAINER_VOLUME="${PSQL_CONTAINER_VOLUME:-psql0}" # set again for delete command
  export PSQL_PORT=

  DRY=
  if [ "${1:-}" = '-n' ]; then
    err DRY run mode
    DRY=echo
    shift
  else
    DRY=
  fi

  container.sh ps > /dev/null ; res=$?
  [ $res -ne 0 ] && errorExit 5 Container environment does not seem to be started or user is not in the required group.

  while true ; do
    case "${1:-}" in
    arch=*)
      export PSQL_CONTAINER_ARCHITECTURE="--platform ${1//arch=/}"
      shift
      echo architecture is:"$PSQL_CONTAINER_ARCHITECTURE"
      ;;
    name=*)
      POSTGRESQL_CONTAINER_LABEL="${1//name=/}"
      shift
      [ -z "$POSTGRESQL_CONTAINER_LABEL" ] && errorExit 6 'empty container label'
      echo container label:"$POSTGRESQL_CONTAINER_LABEL"
      ;;
    volume=*)
      CONTAINER_VOLUME="${1//volume=/}"
      shift
      [ -z "$CONTAINER_VOLUME" ] && err 'empty volume name'
      echo volume label:"$CONTAINER_VOLUME"
      ;;
    image=*)
      export PSQL_IMAGE_NAME="${1/image=/}"
      shift
      echo image:"$PSQL_IMAGE_NAME"
      ;;
    port=*)
      export PSQL_PORT="${1/port=/}"
      shift
      echo port:"$PSQL_PORT"
      ;;
    i|in|ini|init)
      shift
      startContainer "$POSTGRESQL_CONTAINER_LABEL" "$CONTAINER_VOLUME" "$@"
      exit $?
      ;;
    s|start)  
      shift
      container.sh start "$@" "$POSTGRESQL_CONTAINER_LABEL"
      exit $?
      ;;
    e|stop)
      shift
      container.sh stop "$@" "$POSTGRESQL_CONTAINER_LABEL"
      exit $?
      ;;
    delete)
      container.sh stop "$@" "$POSTGRESQL_CONTAINER_LABEL"
      container.sh container rm "$POSTGRESQL_CONTAINER_LABEL"
      container.sh volume rm "$CONTAINER_VOLUME"
      exit $?
      ;;
    stat|status)
      # return exit ne 0 if no running container found
      shift
      local -r output=$(container.sh  ps -q  --filter name="${POSTGRESQL_CONTAINER_LABEL}" "$@")
      [ -z "$output" ] && exit 1
      echo "${POSTGRESQL_CONTAINER_LABEL}":"$output" ; exit 0
      ;;
    -h|h|help|--help)
      helpExit  # exits
      ;;
    version)
      err 1.5.0
      exit 3
      ;;
    *)
      errorExit 4 'ERROR_UNKNOWN_COMMAND:usage:' ${_options}
      ;;
    esac
  done
}

main "$@"

# EOF
