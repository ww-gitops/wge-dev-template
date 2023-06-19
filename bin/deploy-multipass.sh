#!/usr/bin/env bash

# Utility to deploy kind cluster
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] [--hostname <hostname>] " >&2
    echo "This script will deploy a multipass machine" >&2
}

function args() {
  username="$USER"
  hostname=""

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--install") install=true;;
          "--hostname") (( arg_index+=1 )); hostname="${arg_list[${arg_index}]}";;
          "--username") (( arg_index+=1 )); username="${arg_list[${arg_index}]}";;
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

kubectl get cm -n flux-system cluster-config -o json | jq -r '.data | keys[] as $k | "export \($k)=\"\(.[$k])\""' > /tmp/vars.sh
echo "" >> /tmp/vars.sh
source /tmp/vars.sh
export username

if [ -z "${hostname}" ]; then
  echo "No hostname specified" >&2
  usage; exit
fi

set +e
multipass list | grep ${hostname} >/dev/null
ret=$?
set -e
if [ $ret -eq 0 ]; then
  echo "multipass machine ${hostname} already exists, purging" >&2
  multipass delete ${hostname}
  multipass purge
fi

cat resources/multipass-cloud-init.yaml | envsubst > /tmp/cloud-init.yaml

multipass launch --name $hostname --mem 4G --disk 20G --cpus 2 --cloud-init /tmp/cloud-init.yaml
ip="$(multipass info ${hostname} | grep -E "^IPv4:" | awk '{print $2}')"
echo "IP address of multipass machine is ${ip}"

cp /etc/hosts /tmp/hosts-plus
echo "$ip $hostname" >> /tmp/hosts-plus
sudo cp /tmp/hosts-plus /etc/hosts

