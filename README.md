# Template for deploying WGE Cluster

This repository contains the template for deploying a WGE cluster. Copy the contents of this repository into a new repository and follow the instructions below to deploy a WGE cluster.

On a MacBook it is designed to use the Docker Kubernetes deployed from Docker Dashboard but can be used with any Kubernetes cluster. On Linux it will create a Kind cluster. However Kind should still be installed on MacBook to support CAPI creation of local leaf cluster.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [jq](https://stedolan.github.io/jq/download/)
- [openssl](https://www.openssl.org/source/)
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [vault cli](https://www.vaultproject.io/docs/install)
- [terraform](https://www.terraform.io/downloads.html)
- [direnv](https://direnv.net/docs/installation.html)
- 
