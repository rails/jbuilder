resource "aws_subnet" "ps_teimas" {
  vpc_id                  = aws_vpc.vpc_teimas.id
  cidr_block              = var.psn_cidr_block
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnt-teimas"
  }
}