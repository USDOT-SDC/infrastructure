data "aws_vpc" "public" {
  tags = {
    Network = "Public"
  }
}

data "aws_subnets" "public" {
  // Get a list of subnets in the public vpc
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.public.id]
  }
}

data "aws_security_group" "default" {
  // Get the default security group for the public vpc
  vpc_id = data.aws_vpc.public.id
  name = "default"
}
