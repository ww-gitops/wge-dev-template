#!/usr/bin/env bash

# Utility restarting local kubernetes cluster
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] [--delete-tfs]" >&2
    echo "This script will reset docker kubernetes" >&2
}

function args() {
  delete_tfs=0
  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--delete-tfs") delete_tfs=1;;
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

for ns in $(kubectl get ns -o custom-columns=":metadata.name"); do
  for k in $(kubectl get kustomizations.kustomize.toolkit.fluxcd.io -n $ns -o custom-columns=":metadata.name"); do
    flux resume kustomization -n $ns $k &
  done
done

