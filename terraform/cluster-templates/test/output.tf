
output "admin_kubeconfig" {
  description = "admin kubconfig"
  value       = local.admin_kubeconfig
}

output "endpoint" {
  description = "admin kubconfig"
  value       = local.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "admin kubconfig"
  value       = local.cluster_ca_certificate
}

output "client_certificate" {
  description = "admin kubconfig"
  value       = local.client_cert
}

output "client_key" {
  description = "admin kubconfig"
  value       = local.client_key
}