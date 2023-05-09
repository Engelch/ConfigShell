#!/usr/bin/env bash
# shellcheck disable=SC2155 disable=SC2001

# CHANGELOG
# 2.2:
# - rewrite and documentation added
# - version.txt is now checked first
# - shellcheck
# - test-framework in /opt/ConfigShell/lib/tests/version.sh
#
#########################################################################################
# ConfigShell lib 1.1 (codebase 1.0.0)
bashLib="/opt/ConfigShell/lib/bashlib.sh"
[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
source "$bashLib"
unset bashLib

##########################

function usage()
{
    cat <<HERE
NAME
    $_app
SYNOPSIS
    $_app [-D] [-v]
    $_app [-V]
    $_app -h
VERSION
    $_version
DESCRIPTION
    The version.sh is an essential element of our building system. It is
    called by many other scripts to determine the current version of
    the source code. Some build scripts (e.g. for go) only allow to
    create a build if none exists for this version.

    To determine the version number:
    1. The scripts checks for a file version.txt. If this file exists,
       the version number is extracted from this file. Empty lines in
       version.txt are ignored.
    2. Otherwise, it checks for the existence of the file:
       ./versionFilePattern
       If it exists, empty lines are ignored in this file. One line is
       supposed to contain content of the form:
       <<filename>> <<pattern to extract version info from the file>>
       The pattern is applied in case-insensitive mode to given filename
    3. Otherwise, it searches in all *.go files in the CWD if they
       contain a match for the reg-expr pattern 'app.?version[[:space:]]*='
       If exactly one match can be found, the version information is
       extracted from this line.
    4. Otherwise, it fails with exit code 10
OPTIONS
 -D      ::= enable debug output
 -V      ::= output the version number and exit w/ 3
 -h      ::= show usage message and exit with exit w/ 1
 -v      ::= The default output is:
             <<majorVersion>>.<<minorVersion>>.<<patchVersion>>
             When -v is used, the above output is prepended by:
             <<fileName>>:
<<unknown option>>: exit w/ 2
HERE
}

# EXIT 1 usage
# EXIT 2 unknown option
# EXIT 3 show version number of script
function parseCLI() {
    while getopts "hDvV" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  err Debug enabled ; debugSet
                ;;
            V) echo $_version
                exit 3
                ;;
            v)  declare -g _showFileName=TRUE
               debug _showFileName mode selected
                ;;
            h)  usage ; exit 1
                ;;
            *)
                err Help with "$_app" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
}

function main() {
    declare -r _app="$(basename "$0")"
    declare -r _appDir="$(dirname "$0")"
    declare -r _absoluteAppDir=$(cd "$_appDir" || exit 126; /bin/pwd)
    declare -r _version="2.2.0"

    exitIfBinariesNotFound pwd tput basename dirname mktemp

    parseCLI "$@"
    shift "$(( OPTIND - 1 ))"  # not working inside parseCLI
    debug args are "$*"

    readonly versionFile="./version.txt"
    readonly versionFilePattern="./versionFilePattern"

    if [ -f "$versionFile" ] ; then
            [ "$_showFileName" = TRUE ] && echo -n 'version.txt:'
            grep -Ev '^[[:space:]]*#' "$versionFile"| grep -Ev '^$'
            return
    elif [ -f "$versionFilePattern" ] ; then
        # _versionFilePattern can either contain specific filenames to search for version information or a pattern
        _versionFilePattern=$(grep -v '^$' < "$versionFilePattern" | grep -Ev '^[[:space:]]*#' | sed 's/[[:space:]]*#.*$//')
        [ "$(echo "$_versionFilePattern" | wc -w )" -ne 2 ] && 1>&2 echo 'Versionpattern file should be of the format <filename> <pattern for selecting the line in the file>'
        _file=$(echo "$_versionFilePattern" | awk '{ print $1 }')
        _pattern=$(echo "$_versionFilePattern" | awk '{ print $2 }')
        find . -name "$_file" -print | while read -r match; do output=$(grep -iE --colour=never "$_pattern" "$match" /dev/null | grep -v '^$' | grep -vE '^[[:space:]]*#')
            [ -n "$output" ] && if [ "$_showFileName" = TRUE ] ; then
                echo -n "$(sed 's/:.*/:/' <<< "${output}")"
                sed 's/.*[ =]\"//g' <<< "${output}" | sed 's/\".*$//'
            else
                sed 's/^.*://' <<< "$output" | sed 's/.*[ =]\"//g' | sed 's/\".*$//'
            fi
        done
    else
        # find file(s) with app.?version information included. It should result in exactly one file.
        # should only return one line or less => -quit option
        while read -r -d '' matchfile; do
            [ -z "$matchfile" ] && 1>&2 echo Could not determine version file. Variable files returned "$matchfile". && exit 1
            [ "$_showFileName" = TRUE ] && echo -n "$matchfile:"
            grep -EiH --colour=never 'app.?version[[:space:]]*=' "$matchfile" | grep -E --colour=never '[0-9]+\.[0-9]+\.[0-9]+' | tail -n1 | sed 's/.*[ =]\"//g' | sed 's/\".*$//'
        done < <(find . -name \*.go -maxdepth 1 -exec grep -Eiq 'app.?version[[:space:]]*=' {} \; -print0 -quit)
        exit 0
    fi
}


main "$@"

# EOF
