resource "aws_internet_gateway" "igw_teimas" {
  vpc_id = aws_vpc.vpc_teimas.id

  tags = {
    Name = "int_gateway_teimas"
  }

}