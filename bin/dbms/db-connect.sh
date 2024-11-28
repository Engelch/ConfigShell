#!/usr/bin/env bash
# vim: set expandtab: ts=3: sw=3
# shellcheck disable=SC2155 disable=SC2046 disable=SC1090
#
# author: Christian ENGEL mailto:engel-ch@outlook.com

#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
#########################################################################################

# --- Default Script Functions
function usage()
{
    err NAME
    err4 "$App" "<<use-case>>"
    err4 "$App-<<use-case>>"
    err
    err SYNOPSIS
    err4 "$App" '[-D] [-f <<config-file>>] <<use-case>> [ sql cmd ]'
    err4 "$App-<<use-case>>" '[-D] [-f <<config-file>>] [ sql cmd ]'
    err4 'cat <<file.sql>> | db-connect.sh <<use-case>>'
    err4 "$App" '-h'
    err4 "$App" '-V'
    err
    err VERSION
    err4 "$AppVersion"
    err
    err DESCRIPTION
    err4 A script to call DBMS as a user. The database-details are read from a
    err4 database configuration file
    err4
    err4 1. usecase_DB_TYPE=   '<<mysql|mariadb or psql>>'
    err4 2. usecase_HOST=      'IP-address or FDQN'
    err4 3. usecase_PORT=      'port#, can be omitted for default port number'
    err4 4. usecase_USER=      'required: DB-user'
    err4 5. usecase_PW=        'required: DB-pw'
    err4 6. usecase_DB=        'required: DB to connect to in DBMS'
    err
    err OPTIONS
    err4 '-D                    ::= enable debug output'
    err4 '-V                    ::= show version number and exit 11'
    err4 '-h                    ::= show usage message and exit with exit code 1'
    err4 '-f <<cfgFile>>        ::= load the configuration froma cfg file'
    erre '-x                    ::= show expanded output (PSQL only)'
    err4 todo -f not yet implemented
}

# parseCLI parse the cli options.
# EXIT 1    usage
# EXIT 10   explicitly set credentials file not found or not readable
# EXIT 11   version
function parseCLI() {
    declare -g credentialsFile=''
    while getopts "DVf:nhx" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  debugSet ; debug debug enabled
                ;;
            V)  1>&2 echo '1.2.0'
                exit 11
                ;;
            f)  # set config file instead of db-connect.pw[s]
                debug "credentials file explicitly set to ${OPTARG}"
                credentialsFile=${OPTARG}
                [ ! -r "$credentialsFile" ] && errorExit 10 "cannot read or find credentials-file $credentialsFile"
                ;;
            h)  usage ; exit 1
                ;;
            n)  dry="echo" ; echo 1>&2 dry-mode in on
                ;;
            x)  xoutput='--expanded'
                ;;
            *)
                err Help with "$App" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
}

##################### SCRIPT Implementation

# determineUseCase checks the $0 filename to determine the use-case
# EXIT: 10
function determineUseCase() {
    useCaseAsArg=
    if [[ "$1" =~ ^db-connect-.*.sh$ ]] ; then
        usecase=$(echo "$1" | sed -E 's/^db-connect-//' | sed -E s/\.sh$//)
        debug usecase in app-name detected as "$usecase"
    elif [ -n "$2" ] ; then
        useCaseAsArg=TRUE
        usecase="$2"
        debug usecase as argument detected as "$usecase"
    else
        errorExit 10 usecase could not be determined
    fi
}

# setDB called by checkEnoughSettings
# EXIT 32
function setDB() {
    local _database="$1"_DB
    debug help var is "$_database"
    _database=$(eval echo '$'"$_database")
    debug database is "$_database"
    db_db="$_database"
    [ -z "$db_db" ] && errorExit 32 database unset
}

# setPw called by checkEnoughSettings
# EXIT 31
function setPw() {
    local _dbPw="$1"_PW
    debug help var is "$_dbPw"
    _dbPw=$(eval echo '$'"$_dbPw")
    debug pw is "$_dbPw"
    db_pw="$_dbPw"
    [ -z "$db_pw" ] && errorExit 31 user\'s password unset
}

# setUser called by checkEnoughSettings
# EXIT 30 if user not set
function setUser() {
    local _dbUser="$1"_USER
    debug help var is "$_dbUser"
    _dbUser=$(eval echo '$'"$_dbUser")
    debug user is "$_dbUser"
    db_user="$_dbUser"
    [ -z "$db_user" ] && errorExit 30 user unset
}

# setPort called by checkEnoughSettings
# EXIT 29 if not a port number
function setPort() {
    local _dbPort="$1"_PORT
    debug help var is "$_dbPort"
    _dbPort=$(eval echo '$'"$_dbPort")
    debug port is "$_dbPort"
    db_port="$_dbPort"
    [ -z "$db_port" ] && errorExit 29 portname unset
}

# setHostname called by checkEnoughSettings
# More checks would be possible, e.g. is it an IP address or could it be a hostname: effort vs impact says: no.
# EXIT 28 if unsupported DB
function setHostname() {
    local _dbHost="$1"_HOST
    debug help var is "$_dbHost"
    _dbHost=$(eval echo '$'"$_dbHost")
    debug dbhost is "$_dbHost"
    db_host="$_dbHost"
    [ -z "$db_host" ] && errorExit 28 hostname unset
}

# setDbType called by checkEnoughSettings
# EXIT 26 if unsupported DB
function setDbType() {
    local _dbType="$1"_DB_TYPE
    debug help var is "$_dbType"
    _dbType=$(eval echo '$'"$_dbType")
    debug dbtype is "$_dbType"
    case "$_dbType" in
    mysql|mariadb)              debug supported db type
                                db_caller="mysql"
                                ;;
    psql|postgresql|postgres)   debug supported db type
                                db_caller="psql"
                                ;;
    *)                          errorExit 26 non-supported DB
                                ;;
    esac
    db_type="$_dbType"
    debug db_type is "$db_type", caller is "$db_caller"
}

# checkEnoughSettings <<use-case>> <<credentials-file>> is a helper for findCredentialsFile
# EXIT 25
function checkEnoughSettings() {
    declare -l _matchingLines=$(grep -vE '^#' "$2" | grep -c "$1")
    debug _matchingLines "$_matchingLines"
    [ "$_matchingLines" -lt 6 ] && errorExit 25 Not enough settings found for usecase "$1"
    debug ok checkEnoughSettings enough entries
    debug trying to source the credentials file...
    set -e
    source "$2"
    set +e
    setDbType "$1"
    setHostname "$1"
    setPort "$1"
    setUser "$1"
    setPw "$1"
    setDB "$1"
}

# evalCredentialsFile <<usecase>>
# todo check for specified config file
# EXIT 20
#   21
function evalCredentialsFile() {
    debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '...............................................'
    if [ -n "$credentialsFile" ] ; then
        debug "Using explicitly set credentials-file $credentialsFile"
        checkEnoughSettings "$1"  "$credentialsFile"
    elif [ -f db-connect.pw ] ; then
        debug db-connect.pw found
        checkEnoughSettings "$1" db-connect.pw
    elif [ -f db-connect.pws ] ; then
        debug db-connect.pws found
        if [ ! -L db-connect.pws ] ; then
            errorExit 21 db-connect.pws is supposed to be an s-link, but it is not.
        fi
        checkEnoughSettings "$1" db-connect.pws
        return
    else
        errorExit 20 No credentials file found
    fi
    debug "${BASH_SOURCE[0]}::${FUNCNAME[0]}" '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
}

# callDB calls the actual DB
function callDB() {
    debug in "${FUNCNAME[0]}"
    exitIfBinariesNotFound "$db_caller"
    case "$db_caller" in
    psql)       [ -z "$*" ] && debug no command && $dry psql $xoutput postgresql://"$db_user":"$db_pw"@"$db_host":"$db_port"/"$db_db"
                [ -n "$*" ] && debug command supplied && $dry psql $xoutput -c "$*" postgresql://"$db_user":"$db_pw"@"$db_host":"$db_port"/"$db_db"
                ;;
    mysql)      [ -z "$*" ] && debug no command && $dry mysql -h "$db_host" -P "$db_port" -u "$db_user" --password="$db_pw" "$db_db"
                [ -n "$*" ] && debug command supplied && echo "$*" | $dry mysql -h "$db_host" -P "$db_port" -u "$db_user" --password="$db_pw" "$db_db"
                ;;
    *)          errorExit 40 unsupported db_caller "$db_caller" in "${FUNCNAME[0]}"
                ;;
    esac
}

# todo allow call from cmd-line
function main() {
    declare -r App=$(basename "${0}")
    #declare -r AppDir=$(dirname "$0")
    # declare -r _AbsoluteAppDir=$(cd "$_appDir" || exit 99 ; /bin/pwd)
    declare -r AppVersion="1.2.0"      # use semantic versioning
    dry=
    parseCLI "$@"
    shift "$(( OPTIND - 1 ))"  # not working inside parseCLI
    debug args are "$*"
    determineUseCase "$App" "$1"   # continues only if no error
    [ -n "$useCaseAsArg" ] && shift
    evalCredentialsFile "$usecase"  # check if the file exists and it contains enough records for the usecase
    callDB "$*"
}

main "$@"
# EOF
