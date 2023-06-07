variable "vpc_name" {
  type        = string
  description = "the vpc cluster name for subnet tagging"
}

variable "vpc_cidr" {
  type        = string
  description = "vpc cidr range"
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  type        = number
  description = "the number of public subnets to create"
  default     = 3
}

variable "private_subnet_count" {
  type        = number
  description = "the number of privates subnets to create"
  default     = 3
}
