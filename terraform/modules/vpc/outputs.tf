output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "public_subnets" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnets" {
  value = aws_subnet.private_subnets[*].id
}

output "public_route_table" {
  value = aws_route_table.public_rt.id
}

output "private_route_table" {
  value = aws_route_table.private_rt.id
}
