variable "region" {
  type = string
}

variable "default_tags" {
  type = map(string)
  default = {
    "Managed by Terraform" = "True"
    "source" = "Managed by Terraform"
  }
}

variable "tags" {
  type = map(string)
  default = null
}

variable "bucket_name" {
  type = string
}

variable "prefix_name" {
  type = string
}
