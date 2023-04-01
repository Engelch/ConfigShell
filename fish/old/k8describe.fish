function k8describe
    ## k8describe just requires a unique part of the pod-name.
    set _namespace ""
    set args $argv[1..-1]
    [ "$argv[1]" = -n ] && set _namespace "-n $argv[1]" && set args=$argv[3..-1]
    set _pod $($KUBECTL get po $_namespace | grep -i "$args[1]" | cut -d ' ' -f 1)
    set args $args[2..-1]
    $KUBECTL describe $_namespace $_pod "$args"
end
