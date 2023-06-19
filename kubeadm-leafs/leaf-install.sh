#!/usr/bin/env bash

# Utility to install software and configuring Ubuntu to run k8s
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug] " >&2
    echo "This script will install software and configuring Ubuntu to run k8s" >&2
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

export PATH=$PATH:/usr/local/bin
export HOME=/root



echo "Updating system packages & installing required utilities"
sudo apt-get update
sudo apt-get install -y ca-certificates curl jq iproute2 git unzip apt-transport-https gnupg2 vim

curl -s https://fluxcd.io/install.sh | bash

cp /etc/hosts /tmp/hosts-plus
echo "$(hostname -I | awk '{print $2}') $(hostname)" >> /tmp/hosts-plus
sudo cp /tmp/hosts-plus /etc/hosts

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# only needed to set up multicast on Equinix
sudo cat <<EOF | sudo tee /etc/modules-load.d/gre.conf
ip_gre
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe ip_gre

# sysctl params required by setup, params persist across reboots
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sudo systemctl stop apparmor
sudo systemctl disable apparmor 

# Install containerd
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io 

# Generate and save containerd configuration file to its standard location
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Restart containerd to ensure new configuration file usage:
sudo systemctl restart containerd

# Verify containerd is running.
sudo systemctl --no-pager status containerd -l

sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list 

sudo apt update
sudo apt install --allow-change-held-packages -y kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

sudo apt-get install ipvsadm -y
