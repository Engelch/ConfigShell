function common.path.aws.init() {
    debug4 common.path.aws.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ ! -z "$NO_AWS_COMPLETION" ] && debug8 aws completion disabled && return 0
    if [ $(which aws_completer 2>/dev/null | wc -l) -eq 1 ] ; then 
        debug8 aws completer found
        _aws_completer=$(which aws_completer)
        complete -C "$_aws_completer" aws
    fi
    return 0
}

function common.path.aws.del() {
    debug4 common.path.aws.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ ! -z "$NO_AWS_COMPLETION" ] && debug8 aws completion disabled && return 0
    debug8 unloading aws completion
    complete -r aws
    return 0
}

# EOF
