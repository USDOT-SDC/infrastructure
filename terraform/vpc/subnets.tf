resource "aws_subnet" "firewall" {
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnet_firewall.cidr_block
  tags = {
    Name = local.subnet_firewall.name
  }
}

resource "aws_subnet" "routing" {
  count      = length(local.subnets_routing)
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnets_routing[count.index].cidr_block
  tags = {
    Name = local.subnets_routing[count.index].name
  }
}

resource "aws_subnet" "support" {
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnet_support.cidr_block
  tags = {
    Name = local.subnet_support.name
  }
}

resource "aws_subnet" "researcher" {
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnet_researcher.cidr_block
  tags = {
    Name = local.subnet_researcher.name
  }
}

resource "aws_subnet" "infrastructure" {
  count      = length(local.subnets_infrastructure)
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnets_infrastructure[count.index].cidr_block
  tags = {
    Name = local.subnets_infrastructure[count.index].name
  }
}
