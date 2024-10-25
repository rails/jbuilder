resource "aws_route_table_association" "rta_teimas" {
  subnet_id      = aws_subnet.ps_teimas.id
  route_table_id = aws_route_table.rt_teimas.id

  depends_on = [
    aws_route_table.rt_teimas,
  ]
}