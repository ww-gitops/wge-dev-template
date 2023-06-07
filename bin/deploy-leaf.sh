#!/usr/bin/env bash

# Utility to deploy Kubernetes on a target Ubuntu machine
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] [--install] [--username <username>] --hostname <hostname>" >&2
    echo "This script will deploy Kubernetes on a target Ubuntu machine" >&2
    echo "The target machine must be accessible via ssh using hostname, add the hostname to /etc/hosts if needed first" >&2

}

function args() {
  install=""
  username_str=""

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--install") install=true;;
          "--hostname") (( arg_index+=1 )); hostname="${arg_list[${arg_index}]}";;
          "--username") (( arg_index+=1 )); username_str="${arg_list[${arg_index}]}@";;
          "--debug") set -x; debug_str="--debug";;
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

scp -r leafs ${username_str}${hostname}:/tmp

cat .envrc | grep "export GITHUB_MGMT_" > /tmp/env.sh
echo "export GITHUB_TOKEN=${GITHUB_TOKEN}" >> /tmp/env.sh
scp -r /tmp/env.sh ${username_str}${hostname}:/tmp

if [ -n "$install" ]; then
  ssh ${username_str}${hostname} "source /tmp/leafs/leaf-install.sh $debug_str"
fi

ssh ${username_str}${hostname} "source /tmp/leafs/leaf-deploy.sh $debug_str"

scp ${username_str}${hostname}:/tmp/kubeconfig ~/.kube/${hostname}.kubeconfig
