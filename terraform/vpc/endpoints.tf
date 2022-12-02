resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.common.network.vpc.id
  service_name = "com.amazonaws.${var.common.region}.s3"
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
