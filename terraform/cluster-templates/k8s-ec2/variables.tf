variable "region" {
  type        = string
  description = "AWS region for cluster"
  default     = "us-east-1"
}

variable "name" {
  type        = string
  description = "EC2 edge node name"
}

variable "resource_name" {
  type        = string
  description = "resource name"
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

variable "vpc_id" {
  type        = string
  description = "id for vpc"
}


variable "gitlab_url" {
  type        = string
  description = "gitlab url"
  default     = "https://gitlab.com"
}

variable "gitlab_known_hosts" {
  type        = string
  description = "known hosts for gitlab host (use `ssh-keyscan <gitlab_host>` to find key. use the 'ecdsa-sha2-nistp256' key)"
  default     = "gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY="
}

variable "gitlab_token" {
  type        = string
  description = "gitlab token"
  default     = null
  sensitive   = true
}

variable "gitlab_owner" {
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

variable "route53_main_domain" {
  type        = string
  description = "main domain address (leaf domain will be built using <cluster_name>.<route53_main_domain> format)"
}

variable "instance_type" {
  type        = string
  description = "Instance type associated with Node Group"
  default     = "t2.medium"
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

variable "vault_url" {
  type        = string
  description = "vault url"
}

variable "source_cidr" {
  type        = string
  description = "mask for source cidr"
  default     = "0.0.0.0/0"
}

variable "public_subnets_string" {
  type        = string
  description = "comma seperated string of public subnet ids"
}

variable "private_subnets_string" {
  type        = string
  description = "comma seperated string of private subnet ids"
}

