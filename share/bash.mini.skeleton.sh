#!/usr/bin/env -S bash --norc --noprofile

# EXIT 127
# load functions such as errorExit, debug, debugSet
function loadLibs() {
    #########################################################################################
    # ConfigShell lib 1.1 (codebase 1.0.0)
    bashLib="/opt/ConfigShell/lib/bashlib.sh"
    [ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
    # shellcheck source=/opt/ConfigShell/lib/bashlib.sh
    source "$bashLib"
}

# NOEXIT
function help() {
    cat <<- HERE
Synopsis:
    $appName -h | --help
    $appName -V | --version
    $appName [ -D | --debug ]  ...

About:
    TODO

Options:
    -D | --debug                               :- debug output for this shell-script; also see -v
    -h | --help                                :- this help
    --                                         :- pass remaining CLI elements as arguments
HERE
}


# EXIT 1..
function main() {
    loadLibs
    readonly appVersion="0.0.1"
    readonly appName="$(basename "$0")"
    # Options w/ an argument have a colon (:) after the option
    VALID_ARGS=$(getopt -o DVh --long debug,help,version -- "$@")
    if [[ $? -ne 0 ]]; then { 1>&2 echo ERROR invalid arguments; exit 1; }; fi
    eval set -- "$VALID_ARGS"

    while [ : ]; do
        case "$1" in
        -D|--debug) debugSet; debug Debug enabled. ; shift 
            debug appVersion:"$appVersion"
            debug appName:"$appName"
            ;;
        -h|--help)  help ; exit 2 ;;
        -V|--version) verbose="${verbose}v" ; shift ;;
        --) shift; break ;;
        esac
    done

    # do the main tasks
}

main "$@"
