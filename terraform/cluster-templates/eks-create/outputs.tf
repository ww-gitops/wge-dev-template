output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_role_arn" {
  value = module.eks.cluster_role_arn
}

output "oidc_provider_url" {
  value = module.eks.oidc_provider_url
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "cluster_sg_id" {
  value = module.eks.cluster_sg_id
}

output "vpc_id" {
  value = var.vpc_id
}

output "subnet_ids" {
  value = var.private_subnets_string
}

output "vpc_cidr" {
  value = var.vpc_cidr
}

