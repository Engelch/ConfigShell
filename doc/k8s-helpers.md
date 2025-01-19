---
listings: true
template: eisvogel
...
---
title: Kubernetes Helper Commands
author: The ConfigShell Team
...

# Kubernetes Helper Commands

| Command  | Description  |
|---|---|
| k8appl _file_ | kubectl apply -f  |
| k8del _file_ | kubectl delete -f  |
|||
| k8cp | kubectl cp  file unique_part_of_podname |
| k8exec _unique_part_of_podname_ | kubectl exec -it |
| k8logs [-f] _unique_part_of_podname_ | k8logs logs |
|||
| k8deploy-get _deployment-name_ | k get deploy -o wide --show-labels "\$@" |
| k8pod-get | k get pods -o wide --show-labels "\$@" |
| k8describe | k describe "$@" |
| k8svc-get | k get services -o wide --show-labels "\$@" |
| k8svc-aget | k get services -A -o wide --show-labels "\$@" |
|||
| k8cfg-get | k config get-contexts "\$@" |
| k8cfg-set | k config set-context "\$@" |
| k8cfg-use | k config use-context "\$@" |
| k8cfg-view | k config view "\$@" |
| k8namespace-get | k get ns "\$@" |
|||
| k8nodes-get | k get nodes -o wide --show-labels "\$@" |
| k8-ev | k get events --sort-by=.metadata.creationTimestamp "\$@" |
| k8-eva | k get events --sort-by=.metadata.creationTimestamp -A "\$@" |
| k8all-aget  | kubectl get all  |
