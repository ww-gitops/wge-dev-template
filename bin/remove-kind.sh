#!/usr/bin/env bash

# Utility to remove kind cluster
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] [--username <username>] [--cluster-name <hostname>]  [--hostname <hostname>]" >&2
    echo "This script will remove Kubernetes cluster on the local machine or another host" >&2
    echo "The target machine must be accessible via ssh using hostname, add the hostname to /etc/hosts if needed first" >&2

}

function args() {
  install=""
  username_str=""
  hostname=""
  cluster_name="kind"
  debug_str=""

  ssh_opts="-o StrictHostKeyChecking=no"
  scp_opts="-o StrictHostKeyChecking=no"
  ssh_cmd="ssh $ssh_opts"
  scp_cmd="scp $scp_opts"

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--install") install=true;;
          "--cluster-name") (( arg_index+=1 )); cluster_name="${arg_list[${arg_index}]}";;
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

push=""
location="${hostname:-localhost}"
if [ -d "clusters/kind/${location}-$cluster_name" ]; then
  rm -rf clusters/kind/$location-$cluster_name
  git add clusters/kind/$location-$cluster_name
  push=true
fi
if [ -d "clusters/management/clusters/kind/$location-$cluster_name" ]; then
  rm -rf clusters/management/clusters/kind/$location-$cluster_name
  git add clusters/management/clusters/kind/$location-$cluster_name
  push=true
fi

if [  -n "$push" ]; then
  git commit -m "remove files from clusters for kind cluster $location-$cluster_name"
  git pull
  git push
fi


if [ -n "${hostname}" ]; then
  $scp_cmd -r kind-leafs ${username_str}${hostname}:/tmp

  echo "export cluster_name=${cluster_name}" > /tmp/${location}-${cluster_name}-env.sh
  echo "export hostname=${hostname}" >> /tmp/${location}-${cluster_name}-env.sh
  $scp_cmd -r /tmp/${location}-${cluster_name}-env.sh ${username_str}${hostname}:/tmp/env.sh

  $ssh_cmd ${username_str}${hostname} "source /tmp/kind-leafs/leaf-remove.sh $debug_str"
else
  export hostname=localhost
  
  kind-leafs/leaf-remove.sh $debug_str
fi




