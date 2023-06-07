variable "region" {
  type        = string
  description = "AWS region for cluster"
  default     = "us-east-1"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
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

variable "desired_size" {
  type        = number
  description = "Desired number of instances in Node Group"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Max number of instances in Node Group"
  default     = 4
}

variable "min_size" {
  type        = number
  description = "Min number of instances in Node Group"
  default     = 1
}

variable "shrink" {
  type        = bool
  description = "Shrink worker node group"
  default     = false
}

variable "capacity_type" {
  type        = string
  description = "Capacity associated with Node Group (SPOT or ON_DEMAND)"
  default     = null
}

variable "instance_type" {
  type        = string
  description = "Instance type associated with Node Group"
  default     = "t3.large"
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

variable "eks_core_state_bucket" {
  type        = string
  description = "s3 bucket that contains eks core module outputs"
}

variable "eks_core_state_key" {
  type        = string
  description = "key for s3 bucket that contains eks core module outputs"
}

variable "cluster_admin_roles_string" {
  type        = string
  description = "comma seperated string of IAM roles to be granted admin access in eks aws_auth configmap"
  default     = "AdministratorAccess"
}

variable "cluster_admin_users_string" {
  type        = string
  description = "comma seperated string of IAM users to be granted admin access in eks aws_auth configmap"
  default     = "paul.carlton@weave.works"
}

variable "vault_url" {
  type        = string
  description = "management cluster vault url"
  default     = ""
}

variable "vault_token" {
  type        = string
  description = "management cluster vault token"
  default     = ""
}