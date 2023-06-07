#!/usr/bin/env bash

# Utility for initializing wge cluster and terraform environment
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] " >&2
    echo "This script will create AWS s3 bucket for storing terraform state" >&2
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

cluster_name=${CLUSTER_NAME:-mgmt}
repository_name=${cluster_name}-wge

export TF_VAR_prefix_name=${NAMES_PREFIX:-ww-20276}
export TF_VAR_region=${AWS_REGION:-us-west-2}
bucket_name=${TF_VAR_prefix_name}-$(aws sts get-caller-identity --query Account --output text)-${TF_VAR_region}-${BUCKET_NAME:-tf-state}
terraform -chdir=remote-state init
terraform -chdir=remote-state plan -out /tmp/plan-$$
terraform -chdir=remote-state apply "/tmp/plan-$$"
