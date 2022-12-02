output "subnet_firewall" {
  value = aws_subnet.firewall
}

output "subnets_routing" {
  value = aws_subnet.routing
}

output "subnet_support" {
  value = aws_subnet.support
}

output "subnet_researcher" {
  value = aws_subnet.researcher
}

output "subnets_infrastructure" {
  value = aws_subnet.infrastructure
}

# output "debug" {
#   # value = local.EXTERNAL_NET_ip_set_definition
#   value = var.common.network.vpc.cidr_block_associations[*].cidr_block
# }