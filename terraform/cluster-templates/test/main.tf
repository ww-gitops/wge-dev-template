provider "aws" {
  region = var.region

  default_tags {
    tags = merge({
      source   = "Terraform Managed"
      resource = var.resource_name
    }, var.tags, local.tags)
  }
}

locals {
  edge_node_name  = format("%s-%s", var.resource_name, var.name)
  vault_secret_name = format("leaf-clusters/%s-admin-kubeconfig", local.edge_node_name)
  tags = {
    "Name" = local.edge_node_name
  }
}

data "aws_secretsmanager_secret" "leaf_token" {
  name = "vault-leaf-token"
}
data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.leaf_token.id
}

provider "vault" {
  address = var.vault_url
  token = data.aws_secretsmanager_secret_version.current.secret_string
}

data "vault_kv_secret_v2" "admin_kubeconfig" {
  mount = var.leaf_cluster_secrets_path
  name  = local.vault_secret_name
}

locals {
  admin_kubeconfig = nonsensitive(data.vault_kv_secret_v2.admin_kubeconfig.data["value.yaml"])
  cluster_ca_certificate =  base64decode(yamldecode(local.admin_kubeconfig).clusters[0].cluster.certificate-authority-data)
  cluster_endpoint       =  yamldecode(local.admin_kubeconfig).clusters[0].cluster.server
  client_cert            =  base64decode(yamldecode(local.admin_kubeconfig).users[0].user.client-certificate-data)
  client_key             =  base64decode(yamldecode(local.admin_kubeconfig).users[0].user.client-key-data)
}

provider "kubectl" {
  host = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  client_key = local.client_key
  client_certificate = local.client_cert
  load_config_file       = false
}

provider "kubernetes" {
  host = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  client_key = local.client_key
  client_certificate = local.client_cert
}

resource "kubectl_manifest" "cluster_sa" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${local.edge_node_name}
      namespace: default
  YAML
}

resource "kubectl_manifest" "cluster_sa_token" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: ${kubectl_manifest.cluster_sa.name}-token
      namespace: default
      annotations:
        kubernetes.io/service-account.name: ${kubectl_manifest.cluster_sa.name}
    type: kubernetes.io/service-account-token
  YAML

  depends_on = [kubectl_manifest.cluster_sa]
}

data "kubernetes_secret" "cluster_sa_token" {
  metadata {
    name      = kubectl_manifest.cluster_sa_token.name
    namespace = kubectl_manifest.cluster_sa_token.namespace
  }

  depends_on = [kubectl_manifest.cluster_sa_token]
}
