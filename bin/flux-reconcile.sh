#!/usr/bin/env bash

# Utility for reconciling flux kustomizations
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] [--tls-skip] [--aws-dir <aws directory path>]" >&2
    echo "This script will create secrets in Vault" >&2
    echo " The --aws-dir option can be used to specify the path to the directory containing" >&2
    echo " the aws credentials and config files, if not specified the default is ~/.aws" >&2
    echo "use the --tls-skip option to load data prior to ingress certificate setup" >&2
}

function args() {
  tls_skip=""
  aws_dir="${HOME}/.aws"

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--aws-dir") (( arg_index+=1 ));aws_dir=${arg_list[${arg_index}]};;
          "--debug") set -x;;
          "--tls-skip") tls_skip="-tls-skip-verify";;
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


flux reconcile source git flux-system 
flux reconcile kustomization cert-config 
flux reconcile kustomization vault
flux reconcile kustomization secrets 
flux reconcile kustomization dex
flux reconcile kustomization config 
flux reconcile kustomization vault
flux reconcile kustomization config 
flux reconcile kustomization dex
flux reconcile kustomization wge
if [ "$capi" == "true" ]; then
  flux reconcile kustomization capi-templates
  flux reconcile kustomization capi-clusters 
fi