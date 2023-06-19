#!/usr/bin/env bash

# Utility cleasring dynamo lock for terraform object
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)


set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] --tf-object <namespace>/<tf-object-name>" >&2
    echo "This script will delete dynamo table item related to lock for terraform object" >&2
}

function args() {
  tf_object=""
  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--tf-object") (( arg_index+=1 ));tf_object=${arg_list[${arg_index}]};;
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

  if [ -z "$tf_object" ]; then
    echo "missing --tf-object option" >&2
    usage; exit
  fi
  tf_ns=$(echo $tf_object | cut -d'/' -f1)
  tf_name=$(echo $tf_object | cut -d'/' -f2)

}

args "$@"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR/.. >/dev/null
source .envrc

table=$(kubectl get terraforms.infra.contrib.fluxcd.io -n $tf_ns $tf_name -o jsonpath='{.spec.backendConfig}' | jq -r '.customConfiguration' | grep dynamodb_table | cut -f2 -d\")
key=$(kubectl get terraforms.infra.contrib.fluxcd.io -n $tf_ns $tf_name -o jsonpath='{.spec.backendConfig}' | jq -r '.customConfiguration' | grep key | cut -f2 -d\")

echo "aws dynamodb get-item --table-name $table --key '{\"LockID\": {\"S\": \"$table/$key-md5\"}}'" > /tmp/clear-lock.sh
echo "aws dynamodb delete-item --table-name $table --key '{\"LockID\": {\"S\": \"$table/$key-md5\"}}'" >> /tmp/clear-lock.sh
echo "aws dynamodb get-item --table-name $table --key '{\"LockID\": {\"S\": \"$table/$key-md5\"}}'" >> /tmp/clear-lock.sh
. /tmp/clear-lock.sh