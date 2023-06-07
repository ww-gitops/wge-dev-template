resource "kubernetes_service_account_v1" "vault_auth_delegator" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
  }
}

resource "kubernetes_secret_v1" "vault_auth_delegator" {
  metadata {
    name      = kubernetes_service_account_v1.vault_auth_delegator.metadata[0].name
    namespace = kubernetes_service_account_v1.vault_auth_delegator.metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.vault_auth_delegator.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role_binding_v1" "vault_auth_delegator" {
  metadata {
    name = "vault-tokenreview-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vault_auth_delegator.metadata[0].name
    namespace = kubernetes_service_account_v1.vault_auth_delegator.metadata[0].namespace
  }
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.path
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = var.kubernetes_host
  kubernetes_ca_cert     = var.kubernetes_ca_cert
  token_reviewer_jwt     = kubernetes_secret_v1.vault_auth_delegator.data["token"]
  disable_iss_validation = var.disable_iss_validation
}
