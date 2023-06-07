variable "cluster_name" {
  type        = string
  description = "name of cluster to associate permissions with"
}

variable "cluster_oidc_provider_url" {
  type        = string
  description = "url for cluster oidc provider"
}

variable "cluster_oidc_provider_arn" {
  type        = string
  description = "arn for cluster oidc provider"
}

variable "service_account" {
  type        = string
  description = "kubernetes service account"
  default     = "external-secrets-sa"
}

variable "namespace" {
  type        = string
  description = "namespace for kubernetes service account"
  default     = "flux-system"
}
