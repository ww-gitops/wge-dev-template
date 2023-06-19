#!/usr/bin/env bash

# Utility for applying terraform plan
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] [--plan-only] [--no-lock] <template name> [ <template name>]" >&2
    echo "This script will apply a terraform template" >&2
    echo "Specify <template name> to apply desired template in cluster-templates folder" >&2
}

function args() {
  apply="yes"
  lock=""

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--debug") set -x;;
          "--plan-only") unset apply;;
          "--no-lock") lock="-lock=false";;
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

  templates="${arg_list[@]:${arg_index}}"
  if [ -z "${templates}" ]; then
    echo "No templates specified" >&2
    usage; exit
  fi

}

args "$@"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source .envrc
pushd $SCRIPT_DIR/.. >/dev/null


kubectl get cm -n flux-system cluster-config -o json | jq -r '.data | keys[] as $k | "export \($k)=\"\(.[$k])\""' > vars.sh
echo "" >> vars.sh
source vars.sh
rm vars.sh

bucket_name=${prefixName}-${awsAccountId}-${awsRegion}-tf-state

for template in $templates
do
  if [ ! -d terraform/cluster-templates/$template ]; then
    echo "Template $template does not exist" >&2
    exit 1
  fi

  cat terraform/cluster-templates/$template/config-tf.template | envsubst > /tmp/config.tfvars
  echo "" >> /tmp/config.tfvars

  echo "terraform init..."
  set +e
  terraform -chdir=terraform/cluster-templates/$template init  -backend-config="bucket=$bucket_name" -backend-config="dynamodb_table=$bucket_name" \
          -backend-config="region=$awsRegion" -backend-config="key=${mgmtClusterName}/${template}/terraform.tfstate" $lock 2>/tmp/state-$$ 1>&2
  result=$?
  set -e
  if [ $result -ne 0 ]; then
    set +e
    grep 'use "terraform init -reconfigure' /tmp/state-$$ 2>&1 >/dev/null
    result=$?
    set -e
    if [ $result -eq 0 ]; then
      terraform -chdir=terraform/cluster-templates/$template init -backend-config="bucket=$bucket_name" -backend-config="dynamodb_table=$bucket_name" \
          -backend-config="region=$awsRegion" -backend-config="key=$clusterName/$template_name/$resourceName/$template/$clusterName/terraform.tfstate" $lock -reconfigure  2>/tmp/state-$$ 1>&2
    else
      echo "Error initialising terraform state" >&2
      cat /tmp/state-$$ >&2
      exit 1
    fi
  fi
  echo "variables..."
  cat /tmp/config.tfvars

  terraform -chdir=terraform/cluster-templates/$template plan $lock -var-file=/tmp/config.tfvars -out $template.tfplan
  if [ -n "${apply:-}" ]; then
    terraform -chdir=terraform/cluster-templates/$template apply $lock -auto-approve $template.tfplan
  fi


  rm /tmp/config.tfvars
done
