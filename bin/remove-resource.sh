
#!/usr/bin/env bash

# Utility deleting resources
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] --namespace <namespace> --resource-name <resource-name>" >&2
    echo "This script will delete resources" >&2
    echo " The --namespace option is used to specify the namespace" >&2
    echo " The --resource-name option is used to specify the resource name" >&2
}

function args() {
  resource_name=""
  namespace=""

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--namespace") (( arg_index+=1 ));namespace=${arg_list[${arg_index}]};;
          "--resource-name") (( arg_index+=1 ));resource_name=${arg_list[${arg_index}]};;
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

  if [ -z "$namespace" ]; then
    echo "missing --namespace option" >&2
    usage; exit
  fi

  if [ -z "$resource_name" ]; then
    echo "missing --resource_name option" >&2
    usage; exit
  fi
}

args "$@"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR/.. >/dev/null
source .envrc

rm clusters/management/clusters/$namespace/$resource_name.yaml
git add clusters/management/clusters/$namespace/$resource_name.yaml
rm resource-descriptions/$namespace/$resource_name.yaml
git add resource-descriptions/$namespace/$resource_name.yaml

if [[ `git status --porcelain` ]]; then
  git commit -m "remove resource $resource_name in namespace $namespace"
  git pull
  git push
fi
