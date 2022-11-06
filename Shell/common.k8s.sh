# ---- k8s -----------------------------------------------------------------------

function k8Setup() {
   export KUBECTL=kubectl
   alias dfimage="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm chenzj/dfimage" ## find base image for a container OR docker image history
   alias dih='docker image history' ##
   alias k=$KUBECTL  ##
   alias k8=$KUBECTL ##
   alias k8af='$KUBECTL apply -f' ##
   alias k8df='$KUBECTL delete -f' ##
   alias k8c='$KUBECTL config ' ##
   alias k8cg='$KUBECTL config get-contexts' ##
   alias k8cs='$KUBECTL config set-context' ##
   alias k8cu='$KUBECTL config use-context' ##
   alias k8cv='$KUBECTL config view' ##
   alias k8gd='$KUBECTL get deploy -o wide' ##
   alias k8gda='$KUBECTL get deploy -o wide -A' ##
   alias k8gdA=k8gda ##
   alias k8gn='$KUBECTL get nodes -o wide' ##
   alias k8gp='$KUBECTL get pods -o wide' ##
   alias k8gpa='$KUBECTL get pods -A -o wide' ##
   alias k8gpA=k8gpa ##
   alias k8gs='$KUBECTL get services -o wide' ##
   alias k8gsa='$KUBECTL get services -o wide -A' ##
   alias k8gsA=k8gsa ##
   alias k8ns='$KUBECTL get ns' ##
   alias k8ga='$KUBECTL get all' ##
   alias k8gaA='$KUBECTL get all -A' ##
   alias k8gaa=k8gaA ##
   alias k8gaw='$KUBECTL get all -A -o wide' ##
   alias k8gaaw=k8gaw ##
   alias k8gaAw=k8gaw ##
   alias kevents='$KUBECTL get events --sort-by=.metadata.creationTimestamp' ##
   alias k8ev=kevents ##
   alias k8events=kevents ##
   alias k8eva='kevents -A' ##
   alias k8evA=k8eva ##

   function k8describe() { ## supports -n namespace
      ## k8describe just requires a unique part of the pod-name.
      local _namespace=""
      [ "$1" = -n ] && shift && _namespace="-n $1" && shift
      local _pod=$($KUBECTL get po $_namespace | grep -i "$1" | cut -d ' ' -f 1)
      shift
      $KUBECTL describe $_namespace $_pod $*
   }

   function k8exec() { ## supports -n namespace
      ## k8exec just requires a unique part of the pod-name in the given or the default namespace
      ## options: -n namespace
      ## arguments, optional: command, default: /bin/bash
      local _namespace=""
      [ "$1" = -n ] && shift && _namespace="-n $1" && shift
      local _pod=$($KUBECTL get po $_namespace | grep -i "$1" | cut -d ' ' -f 1)
      shift
      cmd=
      [ "$*" = "" ] && cmd=/bin/bash
      $KUBECTL exec $_namespace -it $_pod -- $cmd $*
   }

   function k8logs() { ## supports -n namespace
      ## k8logs just requires a unique part of the pod-name. -f can be specified.
      ## options: -f
      local _namespace=""
      local follow=
      [ "$1" = -f ] && shift && follow=-f
      [ "$1" = -n ] && shift && _namespace="-n $1" && shift
      [ "$1" = -f ] && shift && follow=-f
      local _pod=$($KUBECTL get po $_namespace | grep -i "$1" | cut -d ' ' -f 1)
      $KUBECTL logs $_namespace $follow $_pod
   }

   # help file to show all k8s commands
   function k8help() {
      cat  $PROFILES_CONFIG_DIR/Shell/common.k8s.sh | grep -v '#####'  | grep '##' | sed 's/^[[:space:]]*##$//' | sed 's/^[[:space:]]*## /    /' | sed 's/^[[:space:]]*### /    ## /' |  sed 's/^[[:space:]]*#### /    # /'
   }
   alias k8-help=k8help ##
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
