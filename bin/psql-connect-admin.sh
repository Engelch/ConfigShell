#!/usr/bin/env bash
#
# default script to call PostgreSQL as the admin user with the possibility to execute commands
#
#
# POSTGRESQL_HOSTNAME=
# POSTGRESQL_PORT=
# POSTGRESQL_ADMIN_USER=
# POSTGRESQL_ADMIN_PW=
# POSTGRESQL_ADMIN_DB=
# POSTGRESQL_USERXY_USER=
# POSTGRESQL_USERXY_PW=
# POSTGRESQL_USERXY_DB=

function debugSet()             { DebugFlag=TRUE; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }

if [ "$1" = -d ] ; then
    debugSet
    shift
fi

# check for hidden cfg file
for inputfile in .psql.source.sh _psql.source.sh ; do
    if [ -f "$inputfile" ] ; then
        debug sourcing $inputfile
        source "$inputfile"
    fi
done

# determine the user from the called scripts. All others are supposed to be
# s-links to psql-connect-admin.sh such as psql-connect-user.sh
declare -r _user=$(basename "$0" | sed -E -e 's/^psql-connect-//' -e 's/\.sh$//' | tr '[a-z]' '[A-Z]')
debug User is "$_user"

# we expect to have only one target DBMS, if not set, it is localhost
if [ -z "$POSTGRESQL_HOSTNAME" ] ; then
  POSTGRESQL_HOSTNAME=localhost
  tlsString='?sslmode=disable'
  debug Seting hostname to localhost and no tls
else
    debug POSTGRESQL_HOSTNAME set from outside to "$POSTGRESQL_HOSTNAME"
fi

# if port is not set, default to 5432
if [ -z "$POSTGRESQL_PORT" ] ; then
  POSTGRESQL_PORT=5432
  debug Setting port to default 5432
else
    debug POSTGRESQL_PORT set from outside to "$POSTGRESQL_PORT"
fi

psqluser=POSTGRESQL_${_user}_USER
# if the admin user is not set, default to postgres
if [ -z "${!psqluser}" ] ; then
    eval "${psqluser}"=postgres
    debug Setting "${psqluser}" to postgres
else
    debug "$psqluser" set from outside to "${!psqluser}"
fi

psqlpw=POSTGRESQL_${_user}_PW
# if the pw is not set, ask for it
if [ -z "${!psqlpw}" ] ; then
    read -esrp "Postgres ${_user} pw \(not echoed\):" pw
    eval "${psqlpw}"="$pw"
    unset pw
    debug "$psqlpw" set to to "${!psqlpw}"
else
    debug "$psqlpw" set from outside to "${!psqlpw}"
fi

psqldb=POSTGRESQL_${_user}_DB
if [ -z "${!psqldb}" ] ; then
    eval "${psqldb}"=postgres
    debug echo Setting default DB to postgres
else
    debug "$psqldb" set from outside to "${!psqldb}"
fi

# allow commands added to it
if [ "$*" != '' ] ; then
    cmds="echo \"$*\" |"
    debug Commands found on the command line':' "$cmds"
else
    cmds=""
    debug No commands found on command line
fi

debug postgresql://"${!psqluser}":"${!psqlpw}"@"$POSTGRESQL_HOSTNAME":"$POSTGRESQL_PORT"/"${!psqldb}""$tlsString"
eval "$cmds" psql postgresql://"${!psqluser}":"${!psqlpw}"@"$POSTGRESQL_HOSTNAME":"$POSTGRESQL_PORT"/"${!psqldb}""$tlsString"

# EOF
