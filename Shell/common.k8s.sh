# ---- k8s -----------------------------------------------------------------------

function k8Setup() {
   export KUBECTL=kubectl
   alias dfimage="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm chenzj/dfimage" # find base image for a container OR docker image history
   alias dih='docker image history'
   alias k=$KUBECTL
   alias k8=$KUBECTL
   alias k8c='$KUBECTL config '
   alias k8cg='$KUBECTL config get-contexts'
   alias k8cs='$KUBECTL config set-context'
   alias k8cu='$KUBECTL config use-context'
   alias k8cv='$KUBECTL config view'
   alias k8gn='$KUBECTL get nodes -o wide'
   alias k8gp='$KUBECTL get pods -o wide'
   alias k8gs='$KUBECTL get services -o wide'
   alias k8ns='$KUBECTL get ns'
   alias k8ga='$KUBECTL get all -A -o wide'
   alias kevents='$KUBECTL get events --sort-by=.metadata.creationTimestamp'
   alias k8ev=kevents

   function k8describe() {
      local _pod=$($KUBECTL get po | grep -i "$1" | cut -d ' ' -f 1)
      shift
      $KUBECTL describe $_pod $*
   }

   function k8exec() {
      local _pod=$($KUBECTL get po | grep -i "$1" | cut -d ' ' -f 1)
      shift
      $KUBECTL exec -it $_pod -- ${k8execCmd:-bash} $*
   }

   function k8logs() {
      local _pod=$($KUBECTL get po | grep -i "$1" | cut -d ' ' -f 1)
      $KUBECTL logs "$2" $_pod # $2 for -f
   }

   # help file to show all k8s commands
   function k8help() {
      echo  dfimage="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm chenzj/dfimage" # find base image for a container OR docker image history
      echo  dih='docker image history'
      echo  k=kubectl
      echo  k8=kubectl
      echo  k8c='kubectl config '
      echo  k8cg='kubectl config get-contexts'
      echo  k8cs='kubectl config set-context'
      echo  k8cu='kubectl config use-context'
      echo  k8cv='kubectl config view'
      echo  k8gn='kubectl get nodes -o wide'
      echo  k8gp='kubectl get pods -o wide'
      echo  k8gs='kubectl get services -o wide'
      echo  k8ns='kubectl get ns'
      echo  k8ga='kubectl get all -A -o wide'
      echo  kevents='kubectl get events --sort-by=.metadata.creationTimestamp'
      echo  k8ev=kevents

      function k8describe() {
         local _pod=$(kubectl get po | grep -i "$1" | cut -d ' ' -f 1)
         shift
         kubectl describe $_pod $*
      }
      function k8exec() {
         local _pod=$(kubectl get po | grep -i "$1" | cut -d ' ' -f 1)
         shift
         kubectl exec -it $_pod -- ${k8execCmd:-bash} $*
      }
      function k8logs() {
         local _pod=$(kubectl get po | grep -i "$1" | cut -d ' ' -f 1)
         kubectl logs "$2" $_pod # $2 for -f
      }
   }

   alias k8s-help=k8help
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
