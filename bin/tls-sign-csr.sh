#!/usr/bin/env bash
#
# shellcheck disable=SC2155
#
# RELEASE NOTES / CHANGELOG
# 2.0.0:
# - ECC support
# - Allow creation of key-material only
#
# Author: engel-ch@outlook.com
# License: MIT
#
#########################################################################################
# VARIABLES, CONSTANTS

readonly _app=$(basename "$0")
readonly _appDir=$(dirname "$0")
readonly _absoluteAppDir=$(cd "$_appDir" || errorExit 1 cannot determine absolute path of app_dir; /bin/pwd)
readonly _appVersion="1.0.0" # use semantic versioning
export DebugFlag=${DebugFlag:-FALSE}

# dry run mode, either supposed to be empty or to be echo
declare -g DRY=
# default key-pair length in -g mode
declare -g RSA=4096
# certificate attribute default values
declare -g C=${CSR_KEY_CREATOR_C}
declare -g O=${CSR_KEY_CREATOR_O}
declare -g OU=${CSR_KEY_CREATOR_OU}
declare -g CN=${CSR_KEY_CREATOR_CN}

#########################################################################################

# --- debug: Conditional debugging. All commands begin w/ debug.

function debugSet()             { DebugFlag=TRUE; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'"$*" 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' "$*" 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' "$*" 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:            ' "$*" 1>&2 ; return 0; }

# --- Exits

# function error()        { err 'ERROR:' $*; return 0; } # similar to err but with ERROR prefix and possibility to include
# Write an error message to stderr. We cannot use err here as the spaces would be removed.
function error()        { echo 'ERROR:'"$*" 1>&2;             return 0; }
function error4()       { echo 'ERROR:    '"$*" 1>&2;         return 0; }
function error8()       { echo 'ERROR:        '"$*" 1>&2;     return 0; }
function error12()      { echo 'ERROR:            '"$*" 1>&2; return 0; }

function errorExit()    { EXITCODE="$1" ; shift; error "$*" ; exit "$EXITCODE"; }
function exitIfErr()    { a="$1"; b="$2"; shift; shift; [ "$a" -ne 0 ] && errorExit "$b" App returned "$a $*"; }

function err()          { echo "$*" 1>&2; }                 # just write to stderr
function err4()         { echo '   ' "$*" 1>&2; }           # just write to stderr
function err8()         { echo '       ' "$*" 1>&2; }       # just write to stderr
function err12()        { echo '           ' "$*" 1>&2; }   # just write to stderr

# --- Existance checks
function exitIfBinariesNotFound()       { for file in "$@"; do command -v "$file" &>/dev/null || errorExit 253 binary not found: "$file"; done }
function exitIfPlainFilesNotExisting()  { for file in "$@"; do [ ! -f "$file" ] && errorExit 254 'plain file not found:'"$file" 1>&2; done }
function exitIfFilesNotExisting()       { for file in "$@"; do [ ! -e "$file" ] && errorExit 255 'file not found:'"$file" 1>&2; done }
function exitIfDirsNotExisting()        { for dir in "$@"; do [ ! -d "$dir" ] && errorExit 252 "$APP:ERROR:directory not found:$dir"; done }

# --- Temporary file/directory  creation
# -- file creation -- TMP1=$(tempFile); TMP2=$(tempFile) ;;;; trap "rm -f $TMP1 $TMP2" EXIT
# -- directory creation -- TMPDIR=$(tempDir) ;;;;;  trap "rm -fr $TMPDIR;" EXIT
#
function tempFile()                     { mktemp "${TMPDIR:-/tmp/}$_app.XXXXXXXX"; }
function tempDir()                      { mktemp -d "${TMPDIR:-/tmp/}$_app.YYYYYYYYY"; }
# realpath as shell, argument either supplied as stdin or as $1

# application-specific functions  ===============================================================================

function usage()
{
    err DESCRIPTION
    err4 "$_app" allows to self-sign a CA key
    err
    err4 Using the -k option, keys can be created without a CSR.
    err
    err SYNOPSIS
    err4 "$_app" '[-D] [-d days] [-s] -c ca-basefilename [<<csr-file>> ...]'
    err
    err4 \# help
    err4 "$_app" '-h'
    err
    err VERSION
    err4 $_appVersion
    err
    err OPTIONS
    err4 '-d days           ::= default 365 days until expiry'
    err4 '-c ca-baseanme    ::= filename of the CA certificate'
    err4 '-s                ::= create server certificate'
    err4 '-D                ::= enable debug output'
    err4 '-h                ::= show usage message and exit with exit code 1'
}

# exit 1, 2
function parseCLI() {
    while getopts "Dc:d:hs" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  debugSet
                ;;
            c)  cabase=$OPTARG
                ;;
            d)  days=$OPTARG
                ;;
            h)  usage
                exit 1
                ;;
            s)  serverCert="-extensions server_cert"
                ;;
            *)  err Help with "$_app" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
}

function main() {
    declare -g serverCert=
    exitIfBinariesNotFound pwd basename dirname mktemp openssl nop
    parseCLI "$@"
    shift $(( OPTIND - 1 ))  # not working inside parseCLI
    debug args are "$*"
    args="$@"
    [ $# = 0  ] && args=-

    # subject=$(createSubjectStringC_O_OU_CN "$C" "$O" "$OU" "$CN")

    [ -z "$cabase" ] && errorExit 10 CA basename not set
    exitIfPlainFilesNotExisting "$cabase".key "$cabase".crt
    for arg in "$args" ; do
        debug openssl x509 -req \
            -CA "$cabase".crt -CAkey "$cabase".key "$serverCert" -CAcreateserial \
            -days "${days:-365}" -sha256 -extensions v3_ca \
            -in "$(basename $arg .csr).csr" -out "$(basename $arg .csr).crt"
        # openssl x509 -req \
        #     -CA "$cabase".crt -CAkey "$cabase".key  -CAcreateserial \
        #     -days "${days:-365}" -sha256 -extensions v3_ca \
        #     -in "$(basename $arg .csr).csr" -out "$(basename $arg .csr).crt"
        if [ -z "$serverCert" ] ; then
            openssl x509 -req \
                -CA "$cabase".crt -CAkey "$cabase".key -CAcreateserial \
                -days "${days:-365}" -sha256 \
                -in "$(basename $arg .csr).csr" -out "$(basename $arg .csr).crt"
        else
            openssl x509 -req \
                -CA "$cabase".crt -CAkey "$cabase".key -CAcreateserial "${serverCert:-}" \
                -days "${days:-365}" -sha256 \
                -in "$(basename $arg .csr).csr" -out "$(basename $arg .csr).crt"
        fi
    done
}

main "$@"

# EOF
