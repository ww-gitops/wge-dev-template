variable "service_account_name" {
  type        = string
  description = "name of service account to create for vault auth delegation"
  default     = "vault-auth-delegator"
}

variable "namespace" {
  type        = string
  description = "kubernetes namespace to create service account for vault auth delegation"
  default     = "default"
}

variable "kubernetes_host" {
  type        = string
  description = "host url for kubernetes cluster"
}

variable "kubernetes_ca_cert" {
  type        = string
  description = "ca cert data for kubernetes cluster"
}

variable "disable_iss_validation" {
  type        = bool
  description = "disable jwt issuer validation"
  default     = true
}

variable "path" {
  type        = string
  description = "vault kubernetes auth path"
  default     = "kubernetes"
}
