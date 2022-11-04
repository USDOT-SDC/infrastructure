data "aws_vpc" "public" {
  tags = {
    Network = "Public"
  }
}

data "aws_subnet" "support" {
  vpc_id = data.aws_vpc.public.id
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.public.id]
  }
  filter {
    name   = "tag:Name"
    values = ["Support Workstations"]
  }
}

data "aws_subnet" "researcher" {
  vpc_id = data.aws_vpc.public.id
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.public.id]
  }
  filter {
    name   = "tag:Name"
    values = ["Researcher Workstations"]
  }
}

data "aws_subnet" "three" {
  vpc_id = data.aws_vpc.public.id
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.public.id]
  }
  filter {
    name   = "tag:Name"
    values = ["Subnet 3"]
  }
}

data "aws_subnet" "four" {
  vpc_id = data.aws_vpc.public.id
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.public.id]
  }
  filter {
    name   = "tag:Name"
    values = ["Subnet 4"]
  }
}

data "aws_subnet" "five" {
  vpc_id = data.aws_vpc.public.id
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.public.id]
  }
  filter {
    name   = "tag:Name"
    values = ["Subnet 5"]
  }
}

data "aws_subnet" "six" {
  vpc_id = data.aws_vpc.public.id
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.public.id]
  }
  filter {
    name   = "tag:Name"
    values = ["Subnet 6"]
  }
}

data "aws_security_group" "default" {
  // Get the default security group for the public vpc
  vpc_id = data.aws_vpc.public.id
  name = "default"
}
