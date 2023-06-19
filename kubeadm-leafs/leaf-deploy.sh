#!/usr/bin/env bash

# Utility to deploy kubernetes on Ubuntu
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] " >&2
    echo "This script will deploy Kubernetes on Ubuntu" >&2
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

source /tmp/env.sh

hostname=$(hostname)
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo ipvsadm --clear

# sudo systemctl stop firewalld.service 
# sudo systemctl disable firewalld.service

sudo systemctl stop kubelet
sudo systemctl stop docker
sudo iptables --flush
sudo iptables -tnat --flush
sudo systemctl start kubelet
sudo systemctl start docker
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F

sudo systemctl restart containerd

sleep 5
sudo -E kubeadm init --ignore-preflight-errors=NumCPU --pod-network-cidr "10.10.0.0/16"  --service-cidr "10.11.0.0/16" --kubernetes-version v1.27.0 --apiserver-cert-extra-sans $hostname

mkdir -p $HOME/.kube
sudo cp -rf /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
while [ 1 -eq 1 ]
do
  set +e
  echo "Waiting for kube-apiserver-$hostname to be ready"
  kubectl wait --for=condition=Ready -n kube-system pod/kube-apiserver-$hostname
  ret=$?
  set -e
  if [ $ret -eq 0 ]; then
    break
  fi
  sleep 1
done

sleep 5

while [ 1 -eq 1 ]
do
  set +e
  # kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
  # kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
  kubectl apply -f /tmp/kubeadm-leafs/weave-daemonset-k8s.yaml
  ret=$?
  set -e
  if [ $ret -eq 0 ]; then
    break
  fi
  sleep 1
done

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl get nodes

kubectl get pods -A
sudo systemctl --no-pager status kubelet -l

cat $KUBECONFIG | sed s%https://.*:6443%https://$hostname:6443%g > /tmp/kubeconfig

while [ 1 -eq 1 ]
do
  set +e
  echo "Waiting for coredns to be available"
  kubectl wait --for=condition=Available --timeout=120s -n kube-system deployment.apps/coredns
  ret=$?
  set -e
  if [ $ret -eq 0 ]; then
    break
  fi
  sleep 1
done

flux --version
flux bootstrap github --owner $GITHUB_MGMT_ORG --repository $GITHUB_MGMT_REPO --path kubeadm-leafs/$hostname/flux
