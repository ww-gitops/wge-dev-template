variable "cluster_name" {

}

variable "cluster_ca_certificate" {

}

variable "cluster_endpoint" {

}

variable "repository_name" {
  type        = string
  description = "github repository name to create file in"
  default     = null
}

variable "branch" {
  type    = string
  default = "main"
}

variable "commit_author" {
  type        = string
  description = "Git commit author (defaults to author value from auth)"
  default     = null
}

variable "commit_email" {
  type        = string
  description = "Git commit email (defaults to email value from auth)"
  default     = null
}

variable "commit_message" {
  type        = string
  description = "Git commit message"
  default     = "leaf cluster kubeconfig"
}

variable "vault_secrets_path" {
  type        = string
  description = "vault path to store leaf cluster secrets"
  default     = "secrets"
}
