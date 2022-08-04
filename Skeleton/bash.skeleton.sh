#!/usr/bin/env bash
# vim: set expandtab: ts=3: sw=3
#
# TITLE: $_app
#
# DESCRIPTION: <see usage function below>
#
# CHANGELOG: todo
# - 0.0.1:
#
# COPYRIGHT © 2022 Christian Engel (mailto:engel-ch@outlook.com) todo
#
# Skeleton:
#   0.6   - echo4, echo8, repair exitIfErr
#   0.5   - default option now -D by default
#   0.4.1 - repaired debug4/8/12 echoing directly, no err call deleting spaces
#   0.4.0 - debug4, debug8
#   0.3.1 - usage with information about debug option
#   0.3.0 - clean-up, local changes
#   0.2.0 - use of bash builtin GNU getopts (no support for long options)
#         - bug fix with debug's internal variable DebugFlag
#   0.1.0 - improved exitIfErr
#
# LICENSE: MIT todo
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
# VARIABLES, CONSTANTS

readonly bash_skeleton_version=0.6.0

readonly _app=$(basename $0)
readonly _appDir=$(dirname $0)
readonly _absoluteAppDir=$(cd $_appDir; /bin/pwd)
readonly _appVersion="0.0.1" # use semantic versioning
export DebugFlag=${DebugFlag:-FALSE}
export VerboseFlag=${VerboseFlasg:-FALSE}

#########################################################################################

function so()
# so helps to write a message in reverse mode
# always show such a message.  If known terminal, print the message
# in reverse video mode. This is the other way, not using escape sequences
{
   [ "$1" != on -a "$1" != off ] && return
    if [ "$TERM" = xterm -o "$TERM" = vt100 -o "$TERM" = xterm-256color  -o "$TERM" = screen ] ; then
      [ "$1" = on ] && tput smso
      [ "$1" = off ] && tput rmso
    fi
}

# --- debug: Conditional debugging. All commands begin w/ debug.

function debugSet()             { DebugFlag=TRUE; return 0; }
function debugUnset()           { DebugFlag=; return 0; }
function debugExecIfDebug()     { [ "$DebugFlag" = TRUE ] && $*; return 0; }
function debug()                { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:'$* 1>&2 ; return 0; }
function debug4()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:    ' $* 1>&2 ; return 0; }
function debug8()               { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:        ' $* 1>&2 ; return 0; }
function debug12()              { [ "$DebugFlag" = TRUE ] && echo 'DEBUG:            ' $* 1>&2 ; return 0; }

function verbose()              { [ "$VerboseFlag" = TRUE ] && echo -n $* ; return 0; }
function verbosenl()            { [ "$VerboseFlag" = TRUE ] && echo $* ; return 0; }
function verboseSet()           { VerboseFlag=TRUE; return 0; }

# --- Colour lines. It requires either linux echo or zsh built-in echo

function colBold()      { printf '\e[1m'; return 0; }
function colNormal()    { printf "\e[0m"; return 0; }
function colBlink()     { printf "\e[5m"; return 0; }

function echo4() 						{ echo '   '$* ; return 0; }
function echo8() 						{ echo '       '$* ; return 0; }

# --- Exits

# function error()        { err 'ERROR:' $*; return 0; } # similar to err but with ERROR prefix and possibility to include
# Write an error message to stderr. We cannot use err here as the spaces would be removed.
function error()        { so on; echo 'ERROR:'$* 1>&2;            so off ; return 0; }
function error4()       { so on; echo 'ERROR:    '$* 1>&2;        so off ; return 0; }
function error8()       { so on; echo 'ERROR:        '$* 1>&2;    so off ; return 0; }
function error12()      { so on; echo 'ERROR:            '$* 1>&2;so off ; return 0; }

function warning()      { so on; echo 'WARNING:'$* 1>&2;          so off; return 0; }


function errorExit()    { EXITCODE=$1 ; shift; error $* ; exit $EXITCODE; }
function exitIfErr()    { a="$1"; b="$2"; shift; shift; [ "$a" -ne 0 ] && errorExit $b App returned $a $*; }

function err()          { echo $* 1>&2; }                 # just write to stderr
function err4()         { echo '   ' $* 1>&2; }           # just write to stderr
function err8()         { echo '       ' $* 1>&2; }       # just write to stderr
function err12()        { echo '           ' $* 1>&2; }   # just write to stderr

# --- Existance checks
function exitIfBinariesNotFound()       { for file in $@; do [ $(command -v "$file") ] || errorExit 253 binary not found: $file; done }
function exitIfPlainFilesNotExisting()  { for file in $*; do [ ! -f $file ] && errorExit 254 'plain file not found:'$file 1>&2; done }
function exitIfFilesNotExisting()       { for file in $*; do [ ! -e $file ] && errorExit 255 'file not found:'$file 1>&2; done }
function exitIfDirsNotExisting()        { for dir in $*; do [ ! -d $dir ] && errorExit 252 "$APP:ERROR:directory not found:"$dir; done }


function binaryFoundInPath() {
   command -v "$1" 2>/dev/null 1>&2 && return 0
   return 1
}

function binaryNotFoundInPath() {
   command -v "$1" 2>/dev/null 1>&2 || return 0
   return 1
}

# --- Temporary file/directory  creation
# -- file creation -- TMP1=$(tempFile); TMP2=$(tempFile) ;;;; trap "rm -f $TMP1 $TMP2" EXIT
# -- directory creation -- TMPDIR=$(tempDir) ;;;;;  trap "rm -fr $TMPDIR;" EXIT
#
function tempFile()                     { mktemp ${TMPDIR:-/tmp/}$_app.XXXXXXXX; }
function tempDir()                      { mktemp -d "${TMPDIR:-/tmp/}$_app.YYYYYYYYY"; }
# realpath as shell, argument either supplied as stdin or as $1

# application-specific functions  ===============================================================================

function usage()
{
    err DESCRIPTION
    err
    err $_app
    err SYNOPSIS
    err4 $_app '[-D] [-f] [dir...]'
    err4 $_app '-h'
    err
    err VERSION
    err4 $_appVersion
    err
    err OPTIONS
    err4 '-D      ::= enable debug output'
    err4 '-h      ::= show usage message and exit with exit code 1'
    err4 todo .......
}

function parseCLI() {
    local currentOption
    while getopts "Dfh" options; do         # Loop: Get the next option;
        case "${options}" in                    # TIMES=${OPTARG}
            D)  err Debug enabled ; debugSet
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
    debug forcedMode is ${forcedMode:-FALSE}
    echo todo '(search and replace all todo accordingly)' here more....................
}

main $*

# EOF
