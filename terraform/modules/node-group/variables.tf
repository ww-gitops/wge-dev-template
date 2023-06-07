variable "cluster_name" {
  type        = string
  description = "Name of EKS cluster to place Node Group in"
}

variable "node_group_name" {
  type        = string
  description = "Name of Node Group"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC associated with Node Group"
}

variable "cluster_security_group_id" {
  type        = string
  description = "Security Group ID for main cluster control plane"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnets to associate with Node Group"
}

variable "tags" {
  type        = map(string)
  description = "AWS tags to add to Node Group"
  default     = null
}

variable "resource_tags" {
  type        = map(string)
  description = "AWS tags to add to Node Group instance and volumes"
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "Kubernetes labels to apply to Node Group"
  default     = null
}

variable "capacity_type" {
  type        = string
  description = "Capacity associated with Node Group (SPOT or ON_DEMAND)"
  default     = null
}

variable "volume_size" {
  type        = number
  description = "Volume size of node instance storage"
  default     = 20
}

variable "volume_type" {
  type        = string
  description = "Volume type of node instance storage"
  default     = "gp3"
}

variable "instance_types" {
  type        = list(string)
  description = "List of instance types associated with Node Group"
  default     = null
}

variable "desired_size" {
  type        = number
  description = "Desired number of instances in Node Group"
}

variable "max_size" {
  type        = number
  description = "Max number of instances in Node Group"
}

variable "min_size" {
  type        = number
  description = "Min number of instances in Node Group"
}

variable "ami_type" {
  type        = string
  description = "Type of AMI assoicated with Node Group"
  default     = null
}

variable "additional_policy_arns" {
  type        = set(string)
  description = "Set of additional policy arns to add to Node Group role"
  default     = []
}

variable "autoscaling" {
  type = list(object({
    schedule_name = string
    recurrence    = string
    time_zone     = optional(string)
    min_size      = number
    max_size      = number
    desired_size  = number
  }))
  description = "Autoscaling config for node group"
  default     = []
}
