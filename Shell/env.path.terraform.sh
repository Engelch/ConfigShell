

function env.path.terraform.init() {
    [ ! -z "$NO_TERRAFORM" ] && return
    debug4 env.path.terraform.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    export TERRAFORM=$(command -v terraform 2>/dev/null)
    res=$?

    [ $res -eq 0 ] && debug8 terraform found, loading completion && complete -c $tf terraform
    # complete -C /opt/homebrew/bin/terraform terraform
}

function env.path.terraform.del() {
    [ ! -z "$NO_TERRAFORM" ] && return
    debug4 env.path.terraform.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ ! -z "$TERRAFORM" ] && debug8 removing terraform completion && complete -r $TERRAFORM
}

# EOF
