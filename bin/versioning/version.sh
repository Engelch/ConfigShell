#!/usr/bin/env bash
# shellcheck disable=SC2155 disable=SC2001

# CHANGELOG
# 2.2:
# - rewrite and documentation added
# - version.txt is now checked first
# - shellcheck
# - test-framework in /opt/ConfigShell/lib/tests/version.sh
# - exit code 10 if no version could be determine in default case (else branch)
# - exit code 11 in version.txt case
# - exit code 12
# - exit code 13
# - exit code 14
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
    $_app [-D] [-v] [ <<dir>> ]
    $_app -V
    $_app -h
VERSION
    $_version
DESCRIPTION
    The version.sh is an essential element of our building system. It is
    called by many other scripts to determine the current version of
    the source code. Some build scripts (e.g. for go) only allow to
    create a build if none exists for this version.

    Without a directory specification, the search for files begins in the
    current directory. Otherwise, it begins in the specified directory.
    The directory-name can contain spaces.

    To determine the version number:
    1. The scripts checks for a file version.txt. If this file exists,
       the version number is extracted from this file. Empty lines in
       version.txt are ignored.
       If no version number can be obtained, exit code 11 is returned.
       If multiple lines are obtained, exit code 12 is returned.
    2. Otherwise, it checks for the existence of the file:
       ./versionFilePattern
       If it exists, empty lines are ignored in this file. One line is
       supposed to contain content of the form:
       <<filename>> <<pattern to extract version info from the file>>
       The pattern is applied in case-insensitive mode to given filename.
       If multiple files match, exit code 13 is returned.
    3. Otherwise, it searches in all *.go files in the CWD if they
       contain a match for the reg-expr pattern 'app.?version[[:space:]]*='
       If exactly one match can be found, the version information is
       extracted from this line.
       If multiple files match with version information, exit code 14 is returned.
    4. Otherwise, it fails with exit code 10

    A testing framework exists for version.sh in
    /opt/ConfigShell/lib/tests/version.sh
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
            V)  echo $_version
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
    declare -r _version="2.3.3"

    exitIfBinariesNotFound pwd tput basename dirname mktemp

    parseCLI "$@"
    shift "$(( OPTIND - 1 ))"  # not working inside parseCLI
    debug args are "$*"

    if [ -n "$1" ] ; then
        debug "switch to directory $*"
        cd "$*" || errorExit 10 "directory $* not found."
    fi

    readonly versionFile="./version.txt"
    readonly versionFilePattern="./versionFilePattern"

    if [ -f "$versionFile" ] ; then
            [ "$_showFileName" = TRUE ] && echo -n 'version.txt:'
            output=$(grep -Ev '^[[:space:]]*#' "$versionFile"| grep -Ev '^$')
            [ -z "$output" ] && 1>&2 echo "ERROR:version number could not be obtained from version.txt file." && exit 11
            [ "$(echo "$output" | wc -l)" -gt 1 ] && 1>&2 echo "ERROR:multiple lines were obtained from version.txt file." && exit 12
            echo "$output"
    elif [ -f "$versionFilePattern" ] ; then
        # _versionFilePattern can either contain specific filenames to search for version information or a pattern
        _versionFilePattern=$(grep -v '^$' < "$versionFilePattern" | grep -Ev '^[[:space:]]*#' | sed 's/[[:space:]]*#.*$//')
        _numPattern="$(echo "$_versionFilePattern" | wc -w )" 
        [ "$_numPattern" -ne 2 ] && 1>&2 echo 'Versionpattern file should be of the format <filename> <pattern> for selecting the line in the file, but found words:' "$_numPattern" && exit 15
        _file=$(echo "$_versionFilePattern" | awk '{ print $1 }')
        debug file pattern is "$_file"
        _pattern=$(echo "$_versionFilePattern" | awk '{ print $2 }')
        debug pattern is "$_pattern"
        [ -z "$_pattern" ] && 1>&2 echo Pattern is not set && exit 16
        declare -g fileFound=''
        while read -r -d '' match; do
            output=$(grep -iE --colour=never "$_pattern" "$match" /dev/null | grep -v '^$' | grep -vE '^[[:space:]]*#')
            debug "output is $output"
            [ "$fileFound" = TRUE ] && 1>&2 echo "ERROR:multiple files match for version information" && exit 13
            fileFound=TRUE
            [ -n "$output" ] && if [ "$_showFileName" = TRUE ] ; then
                echo -n "$(sed 's/:.*/:/' <<< "${output}")"
                sed 's/.*[ =]\"//g' <<< "${output}" | sed 's/\".*$//'
            else
                sed 's/^.*://' <<< "$output" | sed 's/.*[ =]\"//g' | sed 's/\".*$//'
            fi
        done < <(find . -name "$_file" -print0) # find .... | while  >>>> executes the while block in a subshell
        [ -z "$fileFound" ] && 1>&2 echo 'ERROR:Version versionFilePattern mode, information could not be determined.' && exit 10
    else
        # find file(s) with app.?version information included. It should result in exactly one file.
        # should only return one line or less => -quit option
        fileFound=''
        while read -r -d '' matchfile; do
            [ "$fileFound" = TRUE ] && 1>&2 echo "ERROR:multiple files match for version information" && exit 14
            fileFound=TRUE
            [ -z "$matchfile" ] && 1>&2 echo Could not determine version file. Variable files returned "$matchfile". && exit 1
            [ "$_showFileName" = TRUE ] && echo -n "$matchfile:"
            grep -EiH --colour=never 'app.?version[[:space:]]*=' "$matchfile" | grep -E --colour=never '[0-9]+\.[0-9]+\.[0-9]+' | tail -n1 | sed 's/.*[ =]\"//g' | sed 's/\".*$//'
        done < <(find . -maxdepth 1 -name \*.go -exec grep -Eiq 'app.?version[[:space:]]*=' {} \; -print0)
        [ -z "$fileFound" ] && 1>&2 echo 'ERROR:Version information could not be determined.' && exit 10
        exit 0
    fi
}


main "$@"

# EOF
