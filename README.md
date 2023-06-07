# Template for deploying WGE Cluster

This repository contains the template for deploying a WGE cluster. Copy the contents of this repository into a new repository and follow the instructions below to deploy a WGE cluster.

On a MacBook it is designed to use the Docker Kubernetes deployed from Docker Dashboard but can be used with any Kubernetes cluster. On Linux it will create a Kind cluster. However Kind should still be installed on MacBook to support CAPI creation of local leaf cluster.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Flux](https://fluxcd.io/docs/installation/)
- [gitops](https://docs.gitops.weave.works/docs/next/installation/weave-gitops/#install-the-gitops-cli)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [jq](https://stedolan.github.io/jq/download/)
- [openssl](https://www.openssl.org/source/)
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [vault cli](https://www.vaultproject.io/docs/install)
- [terraform](https://www.terraform.io/downloads.html) (optional)
- [direnv](https://direnv.net/docs/installation.html) (optional)

## Setup

Once you have copied the contents of this repository into a new repository, you will need to update the `.envrc` file with the correct values for your environment.

If you are using a MacBook start or reset the Kubernetes cluster using the Docker Dashboard. If you are using Linux the `setup.sh` script will create a Kind cluster.

Copy the `resources/github-secrets.sh.template` file to `resources/github-secrets.sh` and update the values for your GitHub organization.

If you want to use OIDC to login to the WGE GUI you will need to configure your GitHub organization for OIDC and add the client keys to the `resources/github-secrets.sh` file. This is optional, the setup script will generate a random password for the `wge-admin` user and store it in the `resources/wge-admin-password.txt` file.

## Deploy

To deploy the WGE cluster run the `setup.sh` script. This will create the WGE cluster and deploy the WGE GUI. If the script fails you can run it again to continue the deployment.

Once Flux has deployed the WGE GUI you can login using the `wge-admin` user and the password in the `resources/wge-admin-password.txt` file or the OIDC login.

## Destroy

To destroy the WGE cluster run the `reset.sh` script. This will destroy the WGE cluster.
