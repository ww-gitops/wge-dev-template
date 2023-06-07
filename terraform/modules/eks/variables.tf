variable "cluster_name" {
  type        = string
  description = "the EKS cluster name"
}

variable "vpc_id" {
  type        = string
  description = "id for vpc"
}

variable "subnet_ids" {
  type        = list(string)
  description = "list of subnet ids to assign to eks cluster"
}

variable "eks_version" {
  type        = string
  description = "EKS version to deploy"
  default     = "1.23"
}
