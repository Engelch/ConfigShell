# ---- k8s -----------------------------------------------------------------------

function k8Setup() {
   export KUBECTL=kubectl
   alias k=$KUBECTL  ##
   alias k8=$KUBECTL ##

   # help file to show all k8s commands
   #function k8help() {
   #   cat  $PROFILES_CONFIG_DIR/Shell/common.k8s.sh | grep -v '#####'  | grep '##' | sed 's/^[[:space:]]*##$//' | sed 's/^[[:space:]]*## /    /' | sed 's/^[[:space:]]*### /    ## /' |  sed 's/^[[:space:]]*#### /    # /'
   #}
   #alias k8-help=k8help ##

   command -v kubectl &>/dev/null && source <(kubectl completion bash) && complete -o default -F __start_kubectl k && complete -o default -F __start_kubectl k8
   return 0
}


function common.k8s.init() {
   debug4 common.k8s.init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   [ ! -z $NO_commonK8s ] && debug exiting common.k8s.sh && return
   k8Setup
}

function common.k8s.del() {
   debug4 common.k8s.del %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}

# EOF
