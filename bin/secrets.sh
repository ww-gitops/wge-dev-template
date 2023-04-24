#!/usr/bin/env bash

# Utility for creating secrets in Vault
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] --wge-entitlement <wge entitlement file> --secrets <secrets file>" >&2
    echo "This script will create secrets in Vault" >&2
}

function args() {
  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--wge-ntitlement") (( arg_index+=1 ));entitlement_file="${arg_list[${arg_index}]}";;
          "--secrets") (( arg_index+=1 ));secrets_file=${arg_list[${arg_index}]};;
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

cluster_name="${CLUSTER_NAME:-support-apps}"
domain_suffix="$(kubectl get cm -n flux-system tf-output-values -o json | jq -r '.data.hostname')"
export VAULT_ADDR="https://vault.$domain_suffix"
export VAULT_TOKEN="$(aws secretsmanager get-secret-value --secret-id ${cluster_name}-vault-keys --query SecretString --output text | jq -r '."root_token"')"
source ${wge_entitlement_file}
vault kv put -mount=secrets wge-entitlement entitlement=${entitlement} username=${username} password=${password}

source ${secrets_file}
vault kv put -mount=secrets git-provider-credentials GITLAB_CLIENT_ID=${GITLAB_CLIENT_ID} GITLAB_CLIENT_SECRET=${GITLAB_CLIENT_SECRET} \
      GITLAB_HOSTNAME=${GITLAB_HOSTNAME} GIT_HOST_TYPE=${GIT_HOST_TYPE}

export WGE_CLIENT_SECRET="$(aws secretsmanager get-secret-value --secret-id ${cluster_name}-dex-config --query SecretString --output text \
  | yq -r '."staticClients"[] | select(.id == "wge") | ."secret"')"
vault kv put -mount=secrets wge-oidc-auth clientID=wge clientSecret=${WGE_DEX_CLIENT_SECRET}

vault kv put -mount=secrets gitlab-repo-read-credentials username=token password=${GITHUB_READ_TOKEN}

vault kv put -mount=secrets leaf-cluster-auth gitlab_token=${GITHUB_TOKEN}

ADMIN_PASSWORD="$(date +%s | sha256sum | base64 | head -c 10)"
BCRYPT_PASSWD=$(echo -n $ADMIN_PASSWORD | gitops get bcrypt-hash)
vault kv put -mount=secrets wge-admin-auth username=wge-admin password=${BCRYPT_PASSWD}

MONITORING_PASSWORD="$(date +%s | sha256sum | base64 | head -c 10)"
vault kv put -mount=secrets monitoring-auth auth=$(htpasswd -nb prometheus-user ${MONITORING_PASSWORD})
vault kv put -mount=secrets monitoring-basic-auth-password password=${MONITORING_PASSWORD}

echo "Admin password is: ${ADMIN_PASSWORD}"
echo "Monitoring password is: ${MONITORING_PASSWORD}"
