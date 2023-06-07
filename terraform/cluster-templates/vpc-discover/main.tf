provider "aws" {
  region = var.region

  default_tags {
    tags = merge({
      source = "Terraform Managed"
    }, var.tags)
  }
}

module "vpc" {
  source               = "../../modules/vpc-discover"
  vpc_name             = var.vpc_name
}
