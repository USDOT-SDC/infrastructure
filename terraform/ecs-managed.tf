data "aws_vpc" "default" {
  filter {
    name   = "tag:Name"
    values = ["Default"]
  }
}

data "aws_security_group" "default" {
  // Get the default security group for the default vpc
  vpc_id = data.aws_vpc.default.id
  name = "default"
}

data "aws_ec2_transit_gateway" "default" {
  filter {
    name   = "tag:Name"
    values = ["Default"]
  }
}
