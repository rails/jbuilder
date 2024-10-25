resource "aws_vpc" "vpc_teimas" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "vpc-teimas"
  }

}