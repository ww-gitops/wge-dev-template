provider "aws" {
  region = var.region

  default_tags {
    tags = merge({
      source = "Terraform Managed"
    }, var.tags)
  }
}

module "eks" {
  source       = "../../modules/eks"
  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id
  subnet_ids   = flatten([split(",", var.public_subnets_string), split(",", var.private_subnets_string)])
}
