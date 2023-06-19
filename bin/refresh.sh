#!/usr/bin/env bash

# Utility refreshing local kubernetes cluster
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug]" >&2
    echo "This script will refresh AWS credentials secrets" >&2
    echo "  --debug: emmit debugging information" >&2
}

function args() {
  bootstrap=0
  reset=0
  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--debug") set -x;;
               "-h") usage; exit;;
           "--help") usage; exit;;
               "-?") usage; exit;;
        *) if [ "${arg_list[${arg_index}]:0:2}" == "--" ];then
               echo "invalid argument: ${arg_list[${arg_index}]}" >&2
               usage; exit
           fi;
           break;;
    esac
    (( arg_index+=1 ))
  done
}

args "$@"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR/.. >/dev/null
source .envrc

aws-secrets.sh

kubectl rollout restart deployment -n flux-system  source-controller 
kubectl rollout restart deployment -n flux-system  kustomize-controller 
kubectl rollout restart deployment -n flux-system  weave-gitops-enterprise-mccp-cluster-service
kubectl rollout restart deployment -n capa-system  capa-controller-manager
