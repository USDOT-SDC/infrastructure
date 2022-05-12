data "aws_vpcs" "public" {
  // Get a list of vpcs with tag: Network = Public tag
  tags = {
    Network = "Public"
  }
}

data "aws_vpc" "public" {
  // Assumes there is only one public vpc, so get the first one in the list
  id = element(tolist(data.aws_vpcs.public.ids), 0)
}

data "aws_subnet_ids" "public" {
  // Get a list of subnets in the public vpc
  vpc_id = data.aws_vpc.public.id
}

data "aws_security_group" "default" {
  // Get the default security group for the public vpc
  vpc_id = data.aws_vpc.public.id
  name = "default"
}
