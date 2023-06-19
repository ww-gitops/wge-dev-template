
variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "github_token" {
  type        = string
  description = "gitlab token"
  default     = null
  sensitive   = true
}

variable "github_owner" {
  type        = string
  description = "gitlab owner"
}

variable "repository_name" {
  type        = string
  description = "github repository name"
}

variable "repository_visibility" {
  type        = string
  description = "How visible is the github repo"
  default     = "private"
}

variable "branch" {
  type        = string
  description = "branch name"
  default     = "main"
}

variable "target_path" {
  type        = string
  description = "flux sync target path"
}

variable "flux_sync_directory" {
  type        = string
  description = "directory within target_path to sync flux"
  default     = "flux"
}

variable "git_commit_author" {
  type        = string
  description = "Git commit author (defaults to author value from auth)"
  default     = null
}

variable "git_commit_email" {
  type        = string
  description = "Git commit email (defaults to email value from auth)"
  default     = null
}

variable "git_commit_message" {
  type        = string
  description = "Set custom commit message"
  default     = null
}

variable "resource_name" {
  type        = string
  description = "template resource name"
  default     = ""
}

variable "template_namespace" {
  type        = string
  description = "template namespace"
  default     = ""
}

variable "cluster_prefix" {
  type        = string
  description = "prefix for cluster name"
  default     = ""
}
