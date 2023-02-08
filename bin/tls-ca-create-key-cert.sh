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
readonly _appVersion="2.0.0" # use semantic versioning
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
    err4 CSR default values can be set using the following environment variables:
    err8 CSR_KEY_CREATOR_C
    err8 CSR_KEY_CREATOR_CN
    err8 CSR_KEY_CREATOR_O
    err8 CSR_KEY_CREATOR_OU
    err
    err SYNOPSIS
    err4 \# also create key pair
    err4 "$_app" '-g [-D] [-n] [-c cn-value ] [-e ecc-cipher] [-o o-value] [-u ou-value] [-s country-value] <base-file-name> ...'
    err
    err4 \# use existing keypair
    err4 "$_app" '[-D] [-n] [-c cn-value ] [-o o-value] [-u ou-value] [-s country-value] <base-file-name>|<pubkeyFile.pub>|<privateKeyFile.key> ...'
    err
    err4 \# key creation only
    err4 "$_app" '-k [-D] [-n] [-e ecc-cipher] <base-file-name> ...'
    err
    err4 \# list ECC ciphers
    err4 "$_app" '-l'
    err
    err4 \# help
    err4 "$_app" '-h'
    err
    err VERSION
    err4 $_appVersion
    err
    err OPTIONS
    err4 '-2      ::= create RSA2048 key material. Implies -g'
    err4 '-c val  ::= set CN field in CSR'
    err4 '-e ciph ::= specify ECC key generation and the cipher to be used. It implies -g'
    err4 '-l      ::= list supported ECC ciphers'
    err4 '-g      ::= generate key pair mode. By default, it is expected to exist'
    err4 '-o val  ::= set O field in CSR, default: Schindler Digital'
    err4 '-u val  ::= set OU field in CSR'
    err4 '-s val  ::= set C field in CSR, default: CH'
    err4 '-y days ::= days until expiry of cert'
    err
    err4 '-D      ::= enable debug output'
    err4 '-n      ::= dry-run mode'
    err4 '-h      ::= show usage message and exit with exit code 1'
}

function parseCLI() {
    while getopts "2Dc:e:ghlno:s:u:y:" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            2)  debug RSA key material 2048bit
                KEY_CREATION=TRUE
                RSA=2048
                ;;
            D)  err Debug enabled
                debugSet
                ;;
            c)  CN=$OPTARG
                debug setting CN to "$CN"
                ;;
            e)  RSA=$OPTARG
                KEY_CREATION=TRUE
                debug ECC cipher mode with cipher "$RSA"
                ;;
            g)  debug create-key mode
                KEY_CREATION='TRUE'
                ;;
            h)  usage
                exit 1
                ;;
            l)  err supported ECC ciphers: "prime256v1|secp384r1|secp521r1"
                exit 1
                ;;
            n)  debug set dry-run mode
                DRY='echo'
                ;;
            o)  O=$OPTARG
                debug setting O to "$O"
                ;;
            s)  C=$OPTARG
                debug setting C to "$C"
                ;;
            u)  OU=$OPTARG
                debug setting OU to "$OU"
                ;;
            y)  days=$OPTARG
                ;;
            *)  err Help with "$_app" -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
}

function keysNotExisting() {
    base=$(basename "$1" .key)
    base=$(basename "$base" .pub)
    base=$(basename "$base" .csr)
    debug base filename is "$base"
    [ -f "$base.key" ] && debug private key existing, returning with 1 && return 1
    [ -f "$base.pub" ] && debug public key existing, returning with 2  && return 2
    debug private and public key not existing, returning with 0
    return 0
}

function keysAlreadyExisting() {
    base=$(basename "$1" .key)
    base=$(basename "$base" .pub)
    base=$(basename "$base" .csr)
    debug base filename is "$base"
    [[ -f "$base.pub"  &&  -f "$base.key" ]] && debug private, public keyfile found, returning with 0 && return 0
    [ ! -f "$base.pub" ] && debug public keyfile not found, returning with 1 && return 1
    [ ! -f "$base.key" ] && debug private keyfile not found, returning with 2 && return 2
    debug should not happen
    return 66
}

function csrAlreadyExisting() {
    base=$(basename "$1" .key)
    base=$(basename "$base" .pub)
    base=$(basename "$base" .csr)
    debug base filename is "$base"
    [ -f "$base.csr" ] && debug csr found, returning 0 && return 0
    debug csr not found, returning 1
    return 1
}

# createKeyPair currentBaseFilename cipherAlgo
# only supports RSA at the moment
# PRE: $base.{key,pub} not yet existing
function createKeyPair() {
    debug in createKeyPair......................
    base=$(basename "$1" .key)      # normalise base name
    base=$(basename "$base" .pub)
    base=$(basename "$base" .csr)
    cipherAlgo="$2"
    case "$cipherAlgo" in
    2048|4096)
        debug createKeyPair RSA with keyAlgoSize "$cipherAlgo"
        # create private key
        eval "$DRY" openssl genpkey -algorithm RSA -out "$base.key" -pkeyopt rsa_keygen_bits:"$cipherAlgo" || errorExit 20 creating private key, exit code was $?
        # output public key from private key
        eval "$DRY" openssl rsa -pubout -in "$base.key" -out "$base.pub" || errorExit 21 creating public key, exit code was $?
        ;;
    prime256v1|secp384r1|secp521r1)
        debug createKeyPair ECC with keyAlgoSize "$cipherAlgo"
        eval "$DRY" openssl ecparam -genkey -name "$cipherAlgo" -noout -out "$base.key"
        eval "$DRY" openssl pkey -in "$base.key" -pubout -out "$base.pub"
        ;;
    *)
        errorExit createKeyPair called with unsupported cipher "$cipherAlgo"
        ;;
    esac

}

# createCsr $base csrAttributeString sanString genericExtension
function createCsr() {
    base=$(basename "$1" .key)      # normalise base name
    base=$(basename "$base" .pub)
    base=$(basename "$base" .csr)
    attr="$2"
    san="$3"
    ext="$4"
    debug createCsr attr:"$attr" san:"$san"
    _san=''
    [ -n "$san" ] && debug san file set && _san="-addext \"subjectAltName = ${san}\"" && debug _san:"$_san"
    _ext=''
    [ -n "$ext" ] && debug ext file set && _ext="-addext \"${ext}\"" && debug _ext:"$_ext"

    csrAlreadyExisting "$base" && errorExit 11 key-material not existing for "$base"
    debug createCsr passed csr not existing, creating csr
    debug       openssl req -key -new "$base.key" -subj "\"$attr\"" "$_san" "$_ext" -out "$base.csr"
    eval "$DRY" openssl req -new -key "$base.key" -subj "\"$attr\"" "$_san" "$_ext" -out "$base.csr"
}

function createSubjectStringC_O_OU_CN() {
    _c=
    [ -n "$C" ] && _c="/C=$C"
    _o=
    [ -n "$O" ] && _o="/O=$O"
    _ou=
    [ -n "$OU" ] && _ou="/OU=$OU"
    _cn=
    [ -n "$CN" ] && _cn="/CN=$CN"
    echo "$_c$_o$_ou$_cn"
}

function main() {
    exitIfBinariesNotFound pwd basename dirname mktemp openssl nop
    parseCLI "$@"
    shift $(( OPTIND - 1 ))  # not working inside parseCLI
    debug args are "$*"
    [ $# = 0  ] && errorExit 3 Not enough arguments supplied, \#Args is $#

    subject=$(createSubjectStringC_O_OU_CN "$C" "$O" "$OU" "$CN")

    for arg in "$@" ; do
        if [ "$KEY_CREATION" = TRUE ] ; then
            debug in key creation mode for "$arg"
            keysNotExisting "$arg" || errorExit 10 key-material or csr already existing for "$arg"
            createKeyPair "$arg" "$RSA"
        fi
        keysAlreadyExisting "$arg" || errorExit 11 key-material not found for "$arg"
        [[ -f "$arg" ]] || arg="$arg".key   # if key is created, then the private key is $arg.key
        openssl req \
            -key "$arg" -subj "$subject" \
            -new -x509 -days "${days:-365}" -sha256 -extensions v3_ca \
            -out "$(basename $arg .key).crt"
    done
}

main "$@"

# EOF
