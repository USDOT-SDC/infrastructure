data "aws_vpc" "default" {
  // Gets the default vpc
  default = true
}

data "aws_subnet_ids" "default" {
  // Get a list of subnets in the default vpc
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "default" {
  // Get the default security group for the default vpc
  vpc_id = data.aws_vpc.default.id
  name = "default"
}
