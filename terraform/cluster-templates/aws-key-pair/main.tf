provider "aws" {
  region = var.region

  default_tags {
    tags = merge({
      source  = "Terraform Managed"
    }, var.tags)
  }
}

resource "aws_key_pair" "ec2" {
  key_name   = var.awsKeyPairName
  public_key = var.sshPubKey
}
