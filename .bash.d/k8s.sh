#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-07-28 14:56:41 +0100 (Sun, 28 Jul 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                              K u b e r n e t e s
# ============================================================================ #

kubectl_opts="${KUBECTL_OPTS:-}"
# set K8S_NAMESPACE in local .bashrc or similar files for environments where your ~/.kube/config
# gets regenerated daily with certification authentication from a kerberos login script, which
# resets the 'kcd bigdata' namespace change. This way you automatically send the right namespace every time
if [ "${K8S_NAMESPACE:-}" ]; then
    kubectl_opts="-n $K8S_NAMESPACE"
fi

k(){
    # want opts auto split, do not quote $kubectl_opts
    # shellcheck disable=SC2086
    kubectl $kubectl_opts "$@"
}

get_pod(){
    local filter="${1:-.*}"
    k get pods | grep "$filter" | head -n1
}

watchpods(){
    watch "
        echo 'Context: '
        echo
        kubectl config current-context
        echo
        echo
        echo 'Pods:'
        echo
        kubectl $kubectl_opts get pods 2>&1
        echo
    "
}

kdesc(){
    k describe "$@"
}

kdp(){
    kdesc pods "$@"
}

kdelp(){
    k delete pod "$@"
}

# this is one of the most used things out there, even more than ping
alias p="k get po"
alias wp=watchpods

alias use="k config use-context"
alias contexts="k config get-contexts"
#alias context="k config current-context"
context(){ k config current-context; }
# contexts has this info and is more useful
#alias clusters="k config get-clusters"

alias kcd='kubectl config set-context $(kubectl config current-context) --namespace'

alias menv='eval $(minikube docker-env)'

k8s_get_token(){
    kubectl describe secret -n kube-system \
        "$(kubectl get secrets -n kube-system | grep default | cut -f1 -d ' ')" |
    grep '^token' |
    #cut -f2 -d':' |
    #tr -d '\t' |
    #tr -d " "
    awk '{print $2}'
}

k8s_get_api(){
    local context
    local cluster
    context="$(context)"
    cluster="$(k config view -o jsonpath="{.contexts[?(@.name == \"$context\")].context.cluster}")"
    k config view -o jsonpath="{.clusters[?(@.name == \"$cluster\")].cluster.server}"
}
