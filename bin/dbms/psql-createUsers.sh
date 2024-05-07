#!/usr/bin/env bash
#
#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && echo 1>&2 "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib
#########################################################################################

set -u

DRY=
if [ "${1:-}" = '-n' ]; then
    1>&2 echo DRY run mode
    DRY=echo
    shift
else
    DRY=
fi

[ ! -r db-connect-localadm.sh ] && errorExit 9 'ERROR_USAGE:cannot find db-connect-localadm.sh'
[ ! -r db-connect.pws ] && errorExit 10 'ERROR_USAGE:cannot find db-connect.pws'
[ ! -L db-connect.pws ] && errorExit 11 'ERROR_USAGE:db-connect.pws is supposed to be an s-link, by convention to db-connect.pw'
source db-connect.pws
# determine users from .pws file
declare -a users
users=$(egrep '127.0.0.1|localhost|::1' db-connect.pws | sed 's/_HOST.*//')

for i in ${users[@]}; do
user=$(echo $i | tr '[A-Z]' '[a-z]')
 pwname="${i}_PW"   # prepare variable name for dynamic variable access
 [ "$user" != localadm ] && printf "\t%s\t" "$user" && $DRY ./db-connect-localadm.sh  "drop user if exists $user; create user $user login password '${!pwname}';"
done
