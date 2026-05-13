resource "aws_subnet" "support" {
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnets.support.cidr_block
  tags = merge(
    {
      Name = local.subnets.support.name
    },
    local.subnet_tags
  )
}

resource "aws_subnet" "researcher" {
  vpc_id     = var.common.network.vpc.id
  cidr_block = local.subnets.researcher.cidr_block
  tags = merge(
    {
      Name = local.subnets.researcher.name
    },
    local.subnet_tags
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
    local.subnet_tags
  )
}
