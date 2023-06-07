output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_role_arn" {
  value = aws_iam_role.cluster_role.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.ca_oidc_provider.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.ca_oidc_provider.url
}

output "cluster_sg_id" {
  value = aws_security_group.cluster_sg.id
}
