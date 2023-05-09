# === Main ===
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

# resource "aws_route_table_association" "main_researcher" {
#   route_table_id = aws_route_table.main.id
#   subnet_id      = aws_subnet.researcher.id
# }

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

# === Firewall ===
resource "aws_route_table" "firewall" {
  vpc_id = var.common.network.vpc.id
  tags = {
    Name = "Firewall"
  }
}

resource "aws_route_table_association" "firewall_firewall" {
  route_table_id = aws_route_table.firewall.id
  subnet_id      = aws_subnet.firewall.id
}

resource "aws_route" "firewall_transit_gateway" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.common.network.transit_gateway.id
  depends_on             = [aws_route_table.firewall]
}


# === Routing ===
resource "aws_route_table" "routing" {
  vpc_id = var.common.network.vpc.id
  tags = {
    Name = "Routing"
  }
}

resource "aws_route_table_association" "routing_routing" {
  count          = length(aws_subnet.routing)
  route_table_id = aws_route_table.routing.id
  subnet_id      = aws_subnet.routing[count.index].id
}

resource "aws_route" "routing_firewall" {
  count                  = length(aws_networkfirewall_firewall.alpha.firewall_status[0].sync_states[*].attachment[0].endpoint_id)
  route_table_id         = aws_route_table.routing.id
  destination_cidr_block = aws_subnet.researcher.cidr_block
  # the firewall's vpc_endpoint_id
  vpc_endpoint_id = (aws_networkfirewall_firewall.alpha.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[count.index]
  depends_on      = [aws_route_table.main]
}

# === Firewalled Subnets ===
resource "aws_route_table" "firewalled" {
  vpc_id = var.common.network.vpc.id
  tags = {
    Name = "Firewalled"
  }
}

resource "aws_route_table_association" "firewalled_researcher" {
  route_table_id = aws_route_table.firewalled.id
  subnet_id      = aws_subnet.researcher.id
}

resource "aws_route" "firewalled_firewall" {
  count                  = length(aws_networkfirewall_firewall.alpha.firewall_status[0].sync_states[*].attachment[0].endpoint_id)
  route_table_id         = aws_route_table.firewalled.id
  destination_cidr_block = "0.0.0.0/0"
  # the firewall's vpc_endpoint_id
  vpc_endpoint_id        = (aws_networkfirewall_firewall.alpha.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[count.index]
  depends_on             = [aws_route_table.firewalled]
}

