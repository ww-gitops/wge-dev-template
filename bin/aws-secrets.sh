#!/usr/bin/env bash

# Utility for creating aws credentials secrets in Vault
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


AWS_ACCESS_KEY_ID=$(cat ${aws_dir}/credentials | grep aws_access_key_id | cut -f2- -d=)
AWS_SECRET_ACCESS_KEY=$(cat ${aws_dir}/credentials | grep aws_secret_access_key | cut -f2- -d=)
AWS_REGION=$(cat ${aws_dir}/config | grep region | cut -f2- -d= | xargs)
AWS_SESSION_TOKEN=$(cat ${aws_dir}/credentials | grep aws_session_token | cut -f2- -d= | cut -f2 -d\")
vault kv put ${tls_skip} -mount=secrets aws-creds  AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
         AWS_REGION=$AWS_REGION AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
