
provider "aws" {
  region = var.region

  default_tags {
    tags = merge(var.default_tags, var.tags)
  }
}

data "aws_caller_identity" "current" {}
locals {
  bucket_name = format("%s-%s-%s-%s", var.prefix_name, data.aws_caller_identity.current.account_id, var.region, var.bucket_name)
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  versioning_configuration {
    status = "Enabled"
  }
  bucket = aws_s3_bucket.terraform_state.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encrypt" {
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  bucket = aws_s3_bucket.terraform_state.id
}

resource "aws_s3_bucket_acl" "private_bucket" {
  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "s3_public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf-state-lock" {
  name           = format("%s-%s-%s-%s", var.prefix_name, data.aws_caller_identity.current.account_id, var.region, var.bucket_name)
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}