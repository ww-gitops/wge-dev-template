#!/usr/bin/env bash

# Helper script to access cluster, source this file to set KUBECONFIG to the cluster 

export CLUSTER_NAME=$1
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME --kubeconfig $HOME/.kube/$AWS_PROFILE-$CLUSTER_NAME.yaml
export KUBECONFIG=$HOME/.kube/$AWS_PROFILE-$CLUSTER_NAME.yaml