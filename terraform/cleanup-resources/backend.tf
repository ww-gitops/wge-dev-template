terraform {
  backend "s3" {
    bucket         = "weaveworks-tfstate-dish"
    key            = "cleanup-resources/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "weaveworks-tfstate-dish-lock"
  }
}
