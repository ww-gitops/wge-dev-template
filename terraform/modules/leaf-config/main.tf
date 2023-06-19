
# Kubectl
resource "kubectl_manifest" "resource_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${var.template_namespace}
  YAML
}

resource "kubectl_manifest" "cluster_sa" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: wge
      namespace: ${var.template_namespace}
  YAML
}

resource "kubectl_manifest" "cluster_sa_token" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: wge-token
      namespace: ${var.template_namespace}
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

locals {
  config_name       = "${var.cluster_name}-kubeconfig"
  vault_secret_name = "leaf-clusters/${local.config_name}"
  kubeconfig = templatefile("${path.module}/templates/kubeconfig.tftpl", {
    cluster = {
      name                       = var.cluster_name,
      certificate_authority_data = var.cluster_ca_certificate,
      server                     = var.cluster_endpoint
    },
    user = {
      name  = kubectl_manifest.cluster_sa.name
      token = data.kubernetes_secret.cluster_sa_token.data.token
    }
  })
}

resource "vault_kv_secret_v2" "kubeconfig" {
  mount               = var.vault_secrets_path
  name                = local.vault_secret_name
  delete_all_versions = true
  data_json           = jsonencode({ "value.yaml" = local.kubeconfig })
}


