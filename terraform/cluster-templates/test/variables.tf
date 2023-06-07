variable "region" {
  type        = string
  description = "AWS region for cluster"
  default     = "us-east-1"
}

variable "name" {
  type        = string
  description = "EC2 edge node name"
  default     = "edge-one"
}

variable "resource_name" {
  type        = string
  description = "resource name"
  default     = "dish-demo1"
}

variable "template_namespace" {
  type        = string
  description = "template namespace"
  default     = "default"
}

variable "tags" {
  type        = map(string)
  description = "resource specific tags"
  default     = {
    customer   = "weaveworks-cx"
    projectGid = "20276"
    creator    = "paul-carlton@weave.works"
  }
}

variable "vault_url" {
  type        = string
  description = "vault url"
  default     = "https://vault.apps.dish-vendor-integration.demo.verica.tech"
}

variable "cluster_secrets_path" {
  type        = string
  description = "vault path for cluster secrets"
  default     = "secrets"
}

variable "leaf_cluster_secrets_path" {
  type        = string
  description = "vault path for leaf cluster secrets"
  default     = "leaf-cluster-secrets"
}

