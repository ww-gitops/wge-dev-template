
data "aws_vpc" "this" {
  filter {
    name = "tag:Name"
    values = [var.var.vpc_name]
  }
}

data "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.this.id
}

data "aws_subnet" "private_subnets" {
  vpc_id                  = aws_vpc.this.id
}
