# ---- k8s -----------------------------------------------------------------------

function k8Setup() {
   export KUBECTL=kubectl
   alias dfimage="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm chenzj/dfimage" ## find base image for a container OR docker image history
   alias dih='docker image history' ##
   alias k=$KUBECTL  ##
   alias k8=$KUBECTL ##
   alias k8c='$KUBECTL config ' ##
   alias k8cg='$KUBECTL config get-contexts' ##
   alias k8cs='$KUBECTL config set-context' ##
   alias k8cu='$KUBECTL config use-context' ##
   alias k8cv='$KUBECTL config view' ##
   alias k8gd='$KUBECTL get deploy -o wide' ##
   alias k8gn='$KUBECTL get nodes -o wide' ##
   alias k8gp='$KUBECTL get pods -o wide' ##
   alias k8gs='$KUBECTL get services -o wide' ##
   alias k8ns='$KUBECTL get ns' ##
   alias k8ga='$KUBECTL get all' ##
   alias k8gaA='$KUBECTL get all -A' ##
   alias k8gaa=k8gaA
   alias k8gaw='$KUBECTL get all -A -o wide' ##
   alias k8gaaw=k8gaw
   alias k8gaAw=k8gaw
   alias kevents='$KUBECTL get events --sort-by=.metadata.creationTimestamp' ##
   alias k8ev=kevents ##
   alias k8events=kevents ##

   function k8describe() { ## supports -n namespace
      ## k8describe just requires a unique part of the pod-name.
      local _namespace=""
      [ "$1" = -n ] && shift && _namespace="-n $1" && shift
      local _pod=$($KUBECTL get po $_namespace | grep -i "$1" | cut -d ' ' -f 1)
      shift
      $KUBECTL describe $_namespace $_pod $*
   }

   function k8exec() { ## supports -n namespace
      ## k8exec just requires a unique part of the pod-name.
      local _namespace=""
      [ "$1" = -n ] && shift && _namespace="-n $1" && shift
      local _pod=$($KUBECTL get po $_namespace | grep -i "$1" | cut -d ' ' -f 1)
      shift
      $KUBECTL exec $_namespace -it $_pod -- $*
   }

   function k8logs() { ## supports -n namespace
      ## k8logs just requires a unique part of the pod-name. -f can be specified.
      local _namespace=""
      [ "$1" = -n ] && shift && _namespace="-n $1" && shift
      local _pod=$($KUBECTL get po $_namespace | grep -i "$1" | cut -d ' ' -f 1)
      $KUBECTL logs $_namespace $2 $_pod # $2 for -f
   }

   # help file to show all k8s commands
   function k8help() {
      cat  $PROFILES_CONFIG_DIR/Shell/common.k8s.sh | grep -v '#####'  | grep '##' | sed 's/^[[:space:]]*##$//' | sed 's/^[[:space:]]*## /    /' | sed 's/^[[:space:]]*### /    ## /' |  sed 's/^[[:space:]]*#### /    # /'
   }
   alias k8-help=k8help ##
   source <(kubectl completion bash) && complete -o default -F __start_kubectl k && complete -o default -F __start_kubectl k8
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
