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

output "debug" {
  value = "debug"
  # value = (aws_networkfirewall_firewall.alpha.firewall_status[0].sync_states[*].attachment[0].endpoint_id)
  #.sync_states[0]
}
