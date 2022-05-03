#!/usr/bin/env bash
# vim: set expandtab: ts=3: sw=3
#
# TITLE:
#
# DESCRIPTION:
#
# CHANGELOG:
# - 0.0.1:
#
# COPYRIGHT © 2022 Christian Engel (mailto:engel-ch@outlook.com)
#
# Skeleton: 
#   0.2.0 - use of bash builtin GNU getopts (no support for long options)
#         - bug fix with debug's internal variable DebugFlag
#   0.1.0 - improved exitIfErr
#
# LICENSE: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#########################################################################################
# VARIABLES

# skeleton_version=0.2.0

readonly _app=$(basename $0)
readonly _appDir=$(dirname $0)
readonly _absoluteAppDir=$(cd $_appDir; /bin/pwd)
readonly _appVersion="0.0.1" # use semantic versioning
DebugFlag=FALSE
VerboseFlag=FALSE

#########################################################################################
# FUNCTIONS

# --- debug: Conditional debugging. All commands begin w/ debug.

function debugSet()             { DebugFlag=TRUE; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debugExecIfDebug()     { [ $DebugFlag = TRUE ] && $*; return 0; }
function debug()                { [ $DebugFlag = TRUE ] && err 'DEBUG:' $* 1>&2 ; return 0; }

function verbose()              { [ "$VerboseFlag" = TRUE ] && echo -n $* ; return 0; }
function verbosenl()            { [ "$VerboseFlag" = TRUE ] && echo $* ; return 0; }
function verboseSet()           { VerboseFlag=TRUE; return 0; }

# --- Colour lines. It requires either linux echo or zsh built-in echo

function colBold()      { printf '\e[1m'; return 0; }
function colNormal()    { printf "\e[0m"; return 0; }
function colBlink()     { printf "\e[5m"; return 0; }

# --- Exits

function error()        { err 'ERROR:' $*; return 0; } # similar to err but with ERROR prefix and possibility to include 
function errorExit()    { EXITCODE=$1 ; shift; error $* 1>&2; exit $EXITCODE; }
function exitIfErr()    { a="$1"; b="$2"; shift; shift; [ "$a" -ne 0 ] && errorExit $b App returned $b $*; }

function err()          { echo $* 1>&2; }                 # just write to stderr
function err4()         { echo '   ' $* 1>&2; }           # just write to stderr
function err8()         { echo '       ' $* 1>&2; }       # just write to stderr
function err12()        { echo '           ' $* 1>&2; }   # just write to stderr

# --- Existance checks
function exitIfBinariesNotFound()       { for file in $@; do [ $(command -v "$file") ] || errorExit 253 binary not found: $file; done }
function exitIfPlainFilesNotExisting()  { for file in $*; do [ ! -f $file ] && errorExit 254 'plain file not found:'$file 1>&2; done }
function exitIfFilesNotExisting()       { for file in $*; do [ ! -e $file ] && errorExit 255 'file not found:'$file 1>&2; done }
function exitIfDirsNotExisting()        { for dir in $*; do [ ! -d $dir ] && errorExit 252 "$APP:ERROR:directory not found:"$dir; done }

# --- Temporary file/directory  creation
# -- file creation -- TMP1=$(tempFile); TMP2=$(tempFile) ;;;; trap "rm -f $TMP1 $TMP2" EXIT
# -- directory creation -- TMPDIR=$(tempDir) ;;;;;  trap "rm -fr $TMPDIR;" EXIT
#
function tempFile()                     { mktemp ${TMPDIR:-/tmp/}$_app.XXXXXXXX; }
function tempDir()                      { mktemp -d "${TMPDIR:-/tmp/}$_app.YYYYYYYYY"; }
# realpath as shell, argument either supplied as stdin or as $1

# MAIN ===============================================================================

function usage()
{
    err $_app
    err SYNOPSIS: 
    err4 $_app '[-d] [-f] [dir...]'
    err4 $_app '-h'
    err DESCRIPTION: 
    err4 $_app '-h      ::= show usage message and exit with exit code 1'
    err4 TODO .......
}

function parseCLI() {
    local currentOption
    while getopts "dfh" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            d)  err Debug enabled ; debugSet     
                ;;
            f)  debug forcedMode; forcedMode=TRUE
                ;;
            h)  usage ; exit 1
                ;;
            *)
                err Help with $_app -h
                exit 2  # Exit abnormally.
                ;;
        esac
    done
}

function main() {
    exitIfBinariesNotFound pwd tput basename dirname mktemp
    parseCLI $* 
    shift $(($OPTIND - 1))  # not working inside parseCLI
    debug args are $*
    debug forcedMode is $forcedMode
    echo TODO '(search and replace all TODO accordingly)' here more....................
}    

main $*

# EOF
