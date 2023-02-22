#!/usr/bin/env bash


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


function err()          { echo $* 1>&2; } # just write to stderr
function err4()         { echo '   ' $* 1>&2; }           # just write to stderr
function err8()         { echo '       ' $* 1>&2; }       # just write to stderr
function err12()        { echo '           ' $* 1>&2; }   # just write to stderr

# --- Existance checks
function exitIfBinariesNotFound()       { for file in $@; do [ $(command -v "$file") ] || errorExit 253 binary not found: $file; done }
function exitIfPlainFilesNotExisting()  { for file in $*; do [ ! -f $file ] && errorExit 254 'plain file not found:'$file 1>&2; done }
function exitIfFilesNotExisting()       { for file in $*; do [ ! -e $file ] && errorExit 255 'file not found:'$file 1>&2; done }
function exitIfDirsNotExisting()        { for dir in $*; do [ ! -d $dir ] && errorExit 252 "$APP:ERROR:directory not found:"$dir; done }


# -d as debug option to show if the correct line is identified
# without -d, the line is reduced to the pure version number.

readonly _app=$(basename $0)
readonly _appDir=$(dirname $0)
readonly _absoluteAppDir=$(cd $_appDir; /bin/pwd)

declare -r _version="2.1.0"

##########################

function usage()
{
    err DESCRIPTION
    err
    err $_app
    err SYNOPSIS
    err4 $_app '[-D] [-v]'
    err4 $_app '-h'
    err4 $_app '-V'
    err
    err VERSION
    err4 $_appVersion
    err
    err OPTIONS
    err4 '-D      ::= enable debug output'
    err4 '-v      ::= show the file-name and the version number'
    err4 '-V      ::= show the version# of script'
}

# EXIT 1 usage
# EXIT 2 unknown option
# EXIT 3 show version number of script
function parseCLI() {
    local currentOption
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

   if [ -f "./versionFilePattern" ] ; then
      # _versionFilePattern can either contain specific filenames to search for version information or a pattern
      _versionFilePattern=$(cat "./versionFilePattern" | grep -v '^$' | egrep -v '^[[:space:]]*#' | sed 's/[[:space:]]*#.*$//')
      [ $(echo $_versionFilePattern | wc -w ) -ne 2 ] && 1>&2 echo 'Versionpattern file should be of the format <filename> <pattern for selecting the line in the file>'
      _file=$(echo $_versionFilePattern | awk '{ print $1 }')
      _pattern=$(echo $_versionFilePattern | awk '{ print $2 }')
      START="egrep -i --colour=never $_pattern $_file /dev/null | grep -v '^$' | egrep -v '^[[:space:]]*#'"
   elif [ -f "./version.txt" ] ; then
        [ "$_showFileName" = TRUE ] && grep -HEv '^$' ./version.txt
        [ "$_showFileName" != TRUE ] && grep -Ev '^$' ./version.txt
        return
   else
      # find file(s) with app.?version information included. It should result in exactly one file.
      # should only return one line or less => -quit option
      files=$(find . -name \*.go -maxdepth 1 -exec egrep -il 'app.?version[[:space:]]*=' {}  \;  -quit)
      debug files:$files
      [ -z "$files" ] && 1>&2 echo Could not determine version file. Variable files returned $files. && exit 1
      START="egrep -iH --colour=never 'app.?version[[:space:]]*=' $files | egrep --colour=never '[0-9]+\.[0-9]+\.[0-9]+' | tail -n1"
   fi

   if [ "$_showFileName" = TRUE ] ; then
      debug _showFileName mode execution
      eval $START
   else
      appVersion=$(eval $START | sed 's/^.*=//' | sed 's/\"//g' | sed 's,//.*,,' | sed 's/[[:space:]]//g' | sed 's/^-//' | sed 's/^.*://' | sed 's/[[:space:]]*#.*$//')
      [ -z "$appVersion" ] && echo could not determine app version 1>&2 && exit 10
      echo $appVersion
   fi
}


main $*