
output "public_ip" {
  description = "instance public ip"
  value       = aws_instance.edge_node.public_ip
}

output "dns_name" {
  description = "instance dns name"
  value       = aws_route53_zone.sub.name
}

output "ssh_key" {
  description = "instance ssh private key"
  value = nonsensitive(tls_private_key.rsa_key.private_key_pem)
}
