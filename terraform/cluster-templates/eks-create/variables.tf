variable "region" {
  type        = string
  description = "aws region"
  default     = "us-east-1"
}

variable "tags" {
  type        = map(string)
  description = "tags for aws resources"

  default     = {
    customer   = "weaveworks-cx"
    projectGid = "20276"
    creator    = "paul-carlton@weave.works"
  }
}

variable "cluster_name" {
  type        = string
  description = "the EKS cluster name"
}

variable "vpc_id" {
  type        = string
  description = "id for vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "cidr for vpc"
}

variable "public_subnets_string" {
  type        = string
  description = "comma seperated string of public subnet ids"
}

variable "private_subnets_string" {
  type        = string
  description = "comma seperated string of private subnet ids"
}

variable "eks_version" {
  type        = string
  description = "EKS version to deploy"
  default     = "1.24"
}
