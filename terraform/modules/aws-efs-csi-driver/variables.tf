variable "cluster_name" {
  type        = string
  description = "EKS cluster to configure EFS with"
}

variable "cluster_oidc_provider_arn" {
  type        = string
  description = "ARN for cluster OIDC provider"
}

variable "cluster_oidc_provider_url" {
  type        = string
  description = "URL for cluster OIDC provider"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC to configure EFS in"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids to create EFS mount targets"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of allowed cidr block to allow access from"
}

variable "performance_mode" {
  type        = string
  description = "EFS performance mode"
  default     = "generalPurpose"
}

variable "service_account" {
  type        = string
  description = "kubernetes service account"
  default     = "efs-csi-controller-sa"
}

variable "namespace" {
  type        = string
  description = "namespace for kubernetes service account"
  default     = "kube-system"
}

variable "create_namespace" {
  type        = bool
  description = "create kubernetes namespace if it doesn't exist"
  default     = false
}

variable "file_path" {
  type        = string
  description = "path to create file in git repo"
  default     = null
}

variable "chart_version" {
  type        = string
  description = "helm chart version of app to deploy"
  default     = null
}

variable "repository_id" {
  type        = string
  description = "gitlab repository id to create file in"
  default     = null
}

variable "branch" {
  type        = string
  description = "branch to commit file"
  default     = "main"
}

variable "commit_author" {
  type        = string
  description = "git commit author"
  default     = null
}

variable "commit_email" {
  type        = string
  description = "git commit email"
  default     = null
}

variable "create_release_file" {
  type        = bool
  description = "create release file in gitlab"
  default     = false
}
