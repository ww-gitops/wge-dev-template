variable "region" {
  type        = string
  description = "aws region"
  default     = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "the vpc cluster name for subnet tagging"
}
