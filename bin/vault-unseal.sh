#!/usr/bin/env bash

# Utility for unsealing vault
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug]" >&2
    echo "This script will initialize vault" >&2
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

export VAULT_ADDR="https://vault.kubernetes.docker.internal"

if [ "$(vault status --format=json | jq -r '.sealed')" == "false" ]; then
  echo "Vault already unsealed"
  exit 0
fi

key1=$(jq -r '.unseal_keys_b64[0]' resources/.vault-init.json)
key2=$(jq -r '.unseal_keys_b64[1]' resources/.vault-init.json)
key3=$(jq -r '.unseal_keys_b64[2]' resources/.vault-init.json)

kubectl -n vault exec --stdin=true --tty=true vault-0 -- vault operator unseal $key1
kubectl -n vault exec --stdin=true --tty=true vault-0 -- vault operator unseal $key2
kubectl -n vault exec --stdin=true --tty=true vault-0 -- vault operator unseal $key3
