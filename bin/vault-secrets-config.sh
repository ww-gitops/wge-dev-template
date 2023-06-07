#!/usr/bin/env bash

# Utility for configuring vault kv secrets engine
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] " >&2
    echo "This script will configure vault" >&2
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

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR/.. >/dev/null
source .envrc

source resources/github-config.sh
source resources/github-secrets.sh

export VAULT_ADDR="https://vault.kubernetes.docker.internal"
export VAULT_TOKEN="$(jq -r '.root_token' resources/.vault-init.json)"
export DEX_URL="https://dex.kubernetes.docker.internal"
export GITHUB_AUTH_ORG=ww-gitops

set +e

vault policy write admin - << EOF
path "*" {
  capabilities = ["create", "read", "update", "patch", "delete", "list", "sudo"]
}
EOF

vault secrets enable -tls-skip-verify -path=secrets kv-v2
vault secrets enable -tls-skip-verify -path=leaf-cluster-secrets kv-v2
