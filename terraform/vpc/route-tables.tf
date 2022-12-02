resource "aws_route_table" "main" {
  vpc_id = var.common.network.vpc.id
  tags = {
    Name = "Main"
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = var.common.network.vpc.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "main_support" {
  route_table_id = aws_route_table.main.id
  subnet_id      = aws_subnet.support.id
}

resource "aws_route_table_association" "main_researcher" {
  route_table_id = aws_route_table.main.id
  subnet_id      = aws_subnet.researcher.id
}

resource "aws_route_table_association" "main_infrastructure" {
  count          = length(aws_subnet.infrastructure)
  route_table_id = aws_route_table.main.id
  subnet_id      = aws_subnet.infrastructure[count.index].id
}

resource "aws_route" "main_transit_gateway" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.common.network.transit_gateway.id
  depends_on             = [aws_route_table.main]
}
