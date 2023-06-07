output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "public_subnets_string" {
  value = join(",", module.vpc.public_subnets)
}

output "private_subnets_string" {
  value = join(",", module.vpc.private_subnets)
}

output "public_route_table" {
  value = module.vpc.public_route_table
}

output "private_route_table" {
  value = module.vpc.private_route_table
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
