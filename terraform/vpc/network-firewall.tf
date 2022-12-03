resource "aws_networkfirewall_firewall" "alpha" {
  name                = "Firewall-Alpha"
  description         = "Firewall controling egress traffic from researcher workstations"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.alpha.arn
  vpc_id              = var.common.network.vpc.id
  subnet_mapping {
    subnet_id = aws_subnet.firewall.id
  }
}

resource "aws_networkfirewall_firewall_policy" "alpha" {
  name = "Firewall-Alpha-Policy"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateless_rule_group_reference {
      priority     = 1
      resource_arn = "arn:aws:network-firewall:us-east-1:505135622787:stateless-rulegroup/Firewall-Alpha-Stateless-Ingress-RuleGroup"
    }
    stateful_rule_group_reference {
      priority     = 2
      resource_arn = "arn:aws:network-firewall:us-east-1:505135622787:stateful-rulegroup/Firewall-Alpha-Stateful-Suricata-RuleGroup"
    }
  }
}

resource "aws_networkfirewall_rule_group" "alpha_stateless_ingress" {
  name        = "Firewall-Alpha-Stateless-Ingress-RuleGroup"
  description = "Allows incoming connections: ICMP, RDP, SSH, etc."
  capacity    = 100
  type        = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              source { address_definition = "0.0.0.0/0" }
              destination { address_definition = "0.0.0.0/0" }
              protocols = [1]
            }
          }
        }
        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6, 17]
              destination { address_definition = aws_subnet.researcher.cidr_block }
              destination_port {
                from_port = 3389
                to_port   = 3389
              }
              source { address_definition = "0.0.0.0/0" }
              source_port {
                from_port = 0
                to_port   = 65535
              }
            }
          }
        }
        stateless_rule {
          priority = 3
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6, 17]
              destination { address_definition = "0.0.0.0/0" }
              destination_port {
                from_port = 0
                to_port   = 65535
              }
              source { address_definition = aws_subnet.researcher.cidr_block }
              source_port {
                from_port = 3389
                to_port   = 3389
              }
            }
          }
        }
        stateless_rule {
          priority = 4
          rule_definition {
            actions = ["aws:pass", ]
            match_attributes {
              protocols = [6]
              destination { address_definition = aws_subnet.researcher.cidr_block }
              destination_port {
                from_port = 22
                to_port   = 22
              }
              source { address_definition = "0.0.0.0/0" }
              source_port {
                from_port = 0
                to_port   = 65535
              }
            }
          }
        }
        stateless_rule {
          priority = 5
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6]
              destination { address_definition = "0.0.0.0/0" }
              destination_port {
                from_port = 0
                to_port   = 65535
              }
              source { address_definition = aws_subnet.researcher.cidr_block }
              source_port {
                from_port = 22
                to_port   = 22
              }
            }
          }
        }
      }
    }
  }
}

locals {
  EXTERNAL_NET_ip_set_definition = "![${join(", ", var.common.network.vpc.cidr_block_associations[*].cidr_block)}]"
}

resource "aws_networkfirewall_rule_group" "alpha_stateful_egress" {
  name        = "Firewall-Alpha-Stateful-Suricata-RuleGroup"
  description = "Advanced rules using Suricata rule syntax"
  type        = "STATEFUL"
  capacity    = 2500
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [aws_subnet.researcher.cidr_block]
        }
      }
      ip_sets {
        key = "EXTERNAL_NET"
        ip_set {
          definition = [local.EXTERNAL_NET_ip_set_definition]
        }
      }
    }
    rules_source {
      rules_string = file("vpc/network-firewall-suricata.rules")
    }
  }
}

resource "aws_networkfirewall_rule_group" "alpha_stateful_tuple_egress" {
  name        = "Firewall-Alpha-Stateful-5-Tuple-RuleGroup"
  description = "5-tuple format, specifying the source IP, source port, destination IP, destination port, and protocol"
  type        = "STATEFUL"
  capacity    = 1000
  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "8.8.8.8/32"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "DNS"
          source           = "0.0.0.0/0"
          source_port      = "ANY"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
      stateful_rule {
        action = "PASS"
        header {
          destination      = "0.0.0.0/0"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "DNS"
          source           = "8.8.8.8/32"
          source_port      = "ANY"
        }
        rule_option {
          keyword = "sid:2"
        }
      }
    }
  }
}
