#!/usr/bin/env bash

# Utility for destroying terraform plan
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] [--plan-only] [--no-lock] <template name>[ <template name>]" >&2
    echo "This script will destroy a terraform template" >&2
    echo "Specify <template name> to destroy desired template in cluster-templates folder" >&2
}

function args() {
  destroy="yes"
  lock=""

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--debug") set -x;;
          "--plan-only") unset destroy;;
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

kubectl get cm -n flux-system tf-output-values -o json | jq -r '.data | keys[] as $k | "export \($k)=\"\(.[$k])\""' > vars.sh
echo "" >> vars.sh
kubectl get cm -n flux-system leaf-cluster-config -o json | jq -r '.data | keys[] as $k | "export \($k)=\"\(.[$k])\""' >> vars.sh
echo "" >> vars.sh
echo "gitlab_token=\"$(kubectl get secret leaf-cluster-auth -o json | jq -r '.data.gitlab_token' | base64 -d)\"" >> vars.sh
echo "" >> vars.sh
source vars.sh
rm vars.sh

bucket_name=${prefixName}-$(aws sts get-caller-identity --query Account --output text)-${awsRegion}-${BUCKET_NAME:-tf-state}
template_name=${TEMPLATE_NAME:-default}

resourceName=${RESOURCE_NAME:-}
if [ -z "${resourceName}" ]; then
    echo "No resource name specified, set RESOURCE_NAME environmental variable" >&2
    usage; exit
fi

clusterName="${CLUSTER:-}"
vpcName="${VPC:-}"

bucket_name=${prefixName}-$(aws sts get-caller-identity --query Account --output text)-${awsRegion}-${BUCKET_NAME:-tf-state}
template_name=${TEMPLATE_NAME:-default}

resourceName=${RESOURCE_NAME:-}
if [ -z "${resourceName}" ]; then
    echo "No resource name specified, set RESOURCE_NAME environmental variable" >&2
    usage; exit
fi

for template in $templates
do
  if [ ! -d cluster-templates/$template ]; then
    echo "Template $template does not exist" >&2
    exit 1
  fi


  cat cluster-templates/$template/config-tf.template | envsubst > /tmp/config.tfvars
  echo "" >> /tmp/config.tfvars
  cat cluster-templates/$template/leaf-tf.template | envsubst >> /tmp/config.tfvars
  echo "" >> /tmp/config.tfvars


  if [  -n "${NAME:-}" ]; then
    echo "name = \"${NAME:-}\"" >> /tmp/config.tfvars
    echo "" >> /tmp/config.tfvars
  fi

  if [  -n "${EQ_TOKEN:-}" ]; then
    echo "metal_auth_token = \"${EQ_TOKEN:-}\"" >> /tmp/config.tfvars
    echo "" >> /tmp/config.tfvars
  fi

  if [  -n "${EQ_PROJECT_ID:-}" ]; then
    echo "project_id = \"${EQ_PROJECT_ID:-}\"" >> /tmp/config.tfvars
    echo "" >> /tmp/config.tfvars
  fi

  if [  -n "${EQ_PROJECT_SSHKEY_ID:-}" ]; then
    echo "project_sshkey_id = \"${EQ_PROJECT_SSHKEY_ID:-}\"" >> /tmp/config.tfvars
    echo "" >> /tmp/config.tfvars
  fi

  if [  -n "${EQ_VLAN_ID:-}" ]; then
    echo "vlan_id = \"${EQ_VLAN_ID:-}\"" >> /tmp/config.tfvars
    echo "" >> /tmp/config.tfvars
  fi

  if [  -n "${GITLAB_TOKEN:-}" ]; then
    echo "gitlab_token = \"${GITLAB_TOKEN:-}\"" >> /tmp/config.tfvars
    echo "" >> /tmp/config.tfvars
  fi

  if [  -n "${VAULT_TOKEN:-}" ]; then
    echo "vault_token = \"${VAULT_TOKEN:-}\"" >> /tmp/config.tfvars
    echo "" >> /tmp/config.tfvars
  fi

  echo "resource_name = \"${resourceName}\"" >> /tmp/config.tfvars
  echo "" >> /tmp/config.tfvars

  echo "terraform init..."
  set +e
  terraform -chdir=cluster-templates/$template init  -backend-config="bucket=$bucket_name" -backend-config="dynamodb_table=$bucket_name" \
          -backend-config="region=$awsRegion" -backend-config="key=$clusterName/$template_name/$resourceName/$template/$clusterName/terraform.tfstate" $lock 2>/tmp/state-$$ 1>&2
  result=$?
  set -e
  if [ $result -ne 0 ]; then
    set +e
    grep 'use "terraform init -reconfigure' /tmp/state-$$ 2>&1 >/dev/null
    result=$?
    set -e
    if [ $result -eq 0 ]; then
      terraform -chdir=cluster-templates/$template init -backend-config="bucket=$bucket_name" -backend-config="dynamodb_table=$bucket_name" \
          -backend-config="region=$awsRegion" -backend-config="key=$clusterName/$template_name/$resourceName/$template/$clusterName/terraform.tfstate" $lock -reconfigure  2>/tmp/state-$$ 1>&2
    else
      echo "Error initialising terraform state" >&2
      cat /tmp/state-$$ >&2
      exit 1
    fi
  fi
  echo "variables..."
  cat /tmp/config.tfvars

  terraform -chdir=cluster-templates/$template plan $lock -var-file=/tmp/config.tfvars -out $template.tfplan
  if [ -n "${destroy:-}" ]; then
    terraform -chdir=cluster-templates/$template destroy $lock -var-file=/tmp/config.tfvars -auto-approve
  fi

  rm /tmp/config.tfvars
done
