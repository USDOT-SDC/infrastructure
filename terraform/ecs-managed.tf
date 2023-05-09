data "aws_vpc" "public" {
  tags = {
    Network = "Public"
  }
}

data "aws_security_group" "default" {
  // Get the default security group for the public vpc
  vpc_id = data.aws_vpc.public.id
  name = "default"
}

data "aws_ec2_transit_gateway" "default" {
  filter {
    name   = "tag:Name"
    values = ["Default"]
  }
}
