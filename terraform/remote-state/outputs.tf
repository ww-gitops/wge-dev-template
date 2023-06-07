output "created" {
  value = {
    "bucket"       = aws_s3_bucket.terraform_state.id
    "dynamo_table" = aws_dynamodb_table.tf-state-lock.name
  }
}

