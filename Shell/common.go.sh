
function setupGo() {
    # increase the version number if a binary is already existing,
    # else compile with the current version number for this release

    alias gopad="increaseVersionNumberIfRequiredAndCompile debug patch"
    alias gopd=gopad
    alias gopa=gopad

    alias gomid="increaseVersionNumberIfRequiredAndCompile debug minor"
    alias gomi="gomid"

    alias gopar="increaseVersionNumberIfRequiredAndCompile release patch"

    alias gomir="increaseVersionNumberIfRequiredAndCompile release minor"

    alias gomad="increaseVersionNumberIfRequiredAndCompile debug major"
    alias goma="gomad"

    alias gomar="increaseVersionNumberIfRequiredAndCompile release major"

    # compile release or debug-build for the current architecture
    alias god=godebug
    alias gor=gorelease

    # execute the lastest version of the binaries
    alias gode='execHelp debug $*'
    alias gore='execHelp release $*'
    alias goue='execHelp upx $*'

}

function increaseVersionNumberIfRequiredAndCompile() {
    checkIfCurrentVersionExisting $1 $2; res=$?
    case $res in
    0)  go$1
        ;;
    1)  bump$2 ; [ $? -ne 0 ] && echo ERRROR executing bump$2, stop && return 2
        go$1
        ;;
    *) 1>&2 echo ERROR:unsupported exit code from checkIfCurrentVersionExisting $res
        return 1
        ;;
    esac
}


# checkIfCurrentVersionExisting checks if a binary exists for the current version, architecture, and environment. Now,
# It just returns the result as a return code.
# checkIfCurrentVersionExisting ( debug | release )
function checkIfCurrentVersionExisting() {
    if [ "$1" = debug -o "$1" = release ] ; then
        declare -r _releaseType=$1
    else
        err Wrong call to checkIfCurrentVersionExisting with '$1' being $1 and should either be debug or release
        return
    fi
    # if [ "$2" = patch -o "$2" = minor -o "$2" = major ] ; then
    #     declare -r _patch=$2
    # else
    #     err Wrong call to checkIfCurrentVersionExisting increase type being $2 and should be either major or minor or patch
    #     return
    # fi
    version.sh > /dev/null ; [ $? -ne 0 ] && 1>&2 echo ERROR:could not determine version number with version.sh. && return 10
    declare -r _binDir=./build
    declare -r _hostarch=$(uname -m | tr "A-Z" "a-z" | sed 's/x86_64/amd64/')
    declare -r _hostostype=$(uname | tr "A-Z" "a-z")
    declare -r _osDir=${_hostostype}_$_hostarch
    declare -r _outputDir=$_binDir/$_releaseType/$_osDir
    declare -r _appName=$(basename $(pwd))
    declare -r _checkname=$_outputDir/${_appName}-$(version.sh)
    debug _appName $_appName
    debug _hostostype $_hostostype
    debug _osDir $_osDir
    debug _outputDir $_outputDir
    debug _version $(version.sh)
    debug _checkname $_outputDir/${_appName}-$(version.sh)
    [ -e $_checkname ] && echo version existing && return 1     # && echo bump$_patch && bump$_patch && echo go$_releaseType && go$_releaseType
    [ ! -e $_checkname ] && echo version NOT existing && return 0           # echo go$_releaseType && go$_releaseType
}

function execHelp() {
    local __os=$(uname | tr "A-Z" "a-z")
    local __app=$(pwd | xargs basename)
    local __arch=$(uname -m | tr "A-Z" "a-z")
    [ "$__arch" = x86_64 ] && __arch=amd64
    [ -z $1 ] && echo execHelp expects an argument. && return
    local __env=$1
    shift

    build/${__env}/${__os}_${__arch}/${__app} $*
}

function common.go.init() {
    debug4 common.go.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ ! -z "$NO_commonGo" ] && debug4 exiting common.go.sh && return
    setupGo
    :
}

function common.go.del() {
    debug4 common.go.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}

# EOF
