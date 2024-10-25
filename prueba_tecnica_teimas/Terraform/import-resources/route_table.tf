resource "aws_route_table" "rt_teimas" {
  vpc_id = aws_vpc.vpc_teimas.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_teimas.id
  }

  tags = {
    Name = "route_table_teimas"
  }
}