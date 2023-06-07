variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "tags" {
  type        = map(string)
  description = "resource tags"
  default     = null
}

variable "ssm_document_name" {
  type        = string
  description = "name of ssm automation document"
  default     = "cluster-resource-cleanup"
}

variable "event_rule_name" {
  type        = string
  description = "name of EventBridge rule"
  default     = "eks-cluster-deletion"
}
