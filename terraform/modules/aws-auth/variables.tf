variable "users" {
  description = "list of user maps to add to aws-auth configmap"
  type = list(object({
    userarn  = string
    groups   = optional(list(string))
    username = optional(string)
  }))
  default = []
}

variable "roles" {
  description = "list of role maps to add to aws-auth configmap"
  type = list(object({
    rolearn  = string
    groups   = optional(list(string))
    username = optional(string)
  }))
  default = []
}

variable "accounts" {
  description = "list of aws accounts to add to aws-auth configmap"
  type        = list(string)
  default     = []
}

variable "node_group_role_arns" {
  description = "list of node group role arns to add to aws-auth configmap (convenience mapper of roles for node groups)"
  type        = list(string)
  default     = []
}

variable "cluster_admin_roles" {
  description = "list of IAM roles to be granted admin access in aws-auth configmap (convenience mapper of roles for cluster admins)"
  type        = list(string)
  default     = []
}

variable "cluster_admin_users" {
  description = "list of IAM users to be granted admin access in aws-auth configmap (convenience mapper of users for cluster admins)"
  type        = list(string)
  default     = []
}
