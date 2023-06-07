variable "region" {
  type        = string
  description = "aws region"
  default     = "us-east-1"
}

variable "tags" {
  type        = map(string)
  description = "tags for aws resources"

  default     = {
    customer   = "weaveworks-cx"
    projectGid = "20276"
    creator    = "paul-carlton@weave.works"
  }
}

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
