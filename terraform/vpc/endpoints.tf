resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.common.network.vpc.id
  service_name = "com.amazonaws.${var.common.region}.s3"
  tags = {
    "Name" = "S3 Gateway"
  }
}

resource "aws_vpc_endpoint_policy" "s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "*",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  route_table_id  = aws_route_table.main.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint" "s3_interface" {
  vpc_id       = var.common.network.vpc.id
  vpc_endpoint_type     = "Interface"
  service_name = "com.amazonaws.${var.common.region}.s3"
  tags = {
    "Name" = "S3 Interface"
  }
}

resource "aws_vpc_endpoint_policy" "s3_interface" {
  vpc_endpoint_id = aws_vpc_endpoint.s3_interface.id
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "*",
        "Resource" : "*"
      }
    ]
  })
}
