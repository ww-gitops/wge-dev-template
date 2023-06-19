#!/usr/bin/env bash

# Utility to remove kind cluster
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] " >&2
    echo "This script will remove Kind Cluster" >&2
}

function args() {
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

source /tmp/env.sh

set +e
kind get clusters | grep -E "^${cluster_name}$" >/dev/null
ret=$?
set -e

if [ $ret -eq 0 ]; then
  echo "Cluster ${cluster_name} already exists, deleting"
  kind delete cluster --name ${cluster_name}
fi

