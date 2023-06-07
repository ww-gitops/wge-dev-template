output "secret_name" {
  description = "name of secret in vault containing kubeconfig"
  value       = local.vault_secret_name
}
