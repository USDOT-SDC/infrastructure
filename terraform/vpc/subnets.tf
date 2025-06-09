# resource "aws_subnet" "firewall" {
#   vpc_id     = var.common.network.vpc.id
#   cidr_block = local.subnet_firewall.cidr_block
#   tags = {
#     Name = local.subnet_firewall.name
#   }
# }

# resource "aws_subnet" "routing" {
#   count      = length(local.subnets_routing)
#   vpc_id     = var.common.network.vpc.id
#   cidr_block = local.subnets_routing[count.index].cidr_block
#   tags = {
#     Name = local.subnets_routing[count.index].name
#   }
# }

resource "aws_subnet" "support" {
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnets.support.cidr_block
  tags = merge(
    {
      Name = local.subnets.support.name
    },
    {
      "Panorama-AWS-Acct"     = "ost-sdc-${var.common.environment}"
      "Panorama-AWS-AllowAll" = "Yes"
    }
  )
}

resource "aws_subnet" "researcher" {
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnets.researcher.cidr_block
  tags = merge(
    {
      Name = local.subnets.researcher.name
    },
    {
      "Panorama-AWS-Acct"     = "ost-sdc-${var.common.environment}"
      "Panorama-AWS-AllowAll" = "Yes"
    }
  )
}

resource "aws_subnet" "infrastructure" {
  count      = length(local.subnets.infrastructures)
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnets.infrastructures[count.index].cidr_block
  tags = merge(
    {
      Name = local.subnets.infrastructures[count.index].name
    },
    {
      "Panorama-AWS-Acct"     = "ost-sdc-${var.common.environment}"
      "Panorama-AWS-AllowAll" = "Yes"
    }
  )
}
