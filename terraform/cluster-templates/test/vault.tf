# resource "vault_policy" "cluster_secrets" {
#   name = "${local.edge_node_name}-secrets"

#   policy = <<-EOF
#     path "${var.cluster_secrets_path}/*" {
#       capabilities = ["read"]
#     }

#     path "${var.leaf_cluster_secrets_path}/*" {
#       capabilities = ["read"]
#     }
#   EOF
# }

# resource "kubernetes_service_account_v1" "external_secrets_vault" {
#   metadata {
#     name      = "vault-secrets-sa"
#     namespace = "flux-system"
#   }
# }

# resource "vault_kubernetes_auth_backend_role" "external_secrets_vault" {
#   backend                          = module.vault_k8s_auth.kubernetes_auth_path
#   role_name                        = "external-secrets-vault"
#   bound_service_account_names      = [kubernetes_service_account_v1.external_secrets_vault.metadata[0].name]
#   bound_service_account_namespaces = [kubernetes_service_account_v1.external_secrets_vault.metadata[0].namespace]
#   token_ttl                        = 3600
#   token_policies                   = ["default", vault_policy.cluster_secrets.name]
# }

# module "vault_k8s_auth" {
#   source             = "../../modules/vault-k8s-auth"
#   kubernetes_host    = local.cluster_endpoint
#   kubernetes_ca_cert = local.cluster_ca_certificate
#   path               = local.edge_node_name
# }
