variable "cluster_name" {

}

variable "cluster_ca_certificate" {

}

variable "cluster_endpoint" {

}

variable "vault_secrets_path" {
  type        = string
  description = "vault path to store leaf cluster secrets"
  default     = "secrets"
}

variable "template_namespace" {
  type        = string
  description = "template namespace"
  default     = ""
}