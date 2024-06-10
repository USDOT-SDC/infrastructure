# S3 Gateway
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = var.common.network.vpc.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.common.region}.s3"
  tags = {
    "Name" = "S3 Gateway"
  }
}

resource "aws_vpc_endpoint_policy" "s3_gateway" {
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway.id
  policy = jsonencode(
    {
      "Version" : "2008-10-17",
      "Statement" : [
        {
          "Sid" : "AllowAll",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "*",
          "Resource" : "*"
        },
        {
          "Sid" : "EnforceTLSv12orHigher",
          "Effect" : "Deny",
          "Principal" : "*",
          "Action" : "*",
          "Resource" : "*",
          "Condition" : {
            "NumericLessThan" : {
              "s3:TlsVersion" : 1.2
            }
          }
        }
      ]
    }
  )
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  route_table_id  = aws_route_table.main.id
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway.id
}

# DynamoDB Gateway
resource "aws_vpc_endpoint" "dynamodb_gateway" {
  vpc_id            = var.common.network.vpc.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.common.region}.dynamodb"
  tags = {
    "Name" = "DynamoDB Gateway"
  }
}

resource "aws_vpc_endpoint_policy" "dynamodb_gateway" {
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb_gateway.id
  policy = jsonencode(
    {
      "Version" : "2008-10-17",
      "Statement" : [
        {
          "Sid" : "AllowAll",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "*",
          "Resource" : "*"
        },
        {
          "Sid" : "EnforceTLSv12orHigher",
          "Effect" : "Deny",
          "Principal" : "*",
          "Action" : "*",
          "Resource" : "*",
          "Condition" : {
            "NumericLessThan" : {
              "dynamodb:TlsVersion" : 1.2
            }
          }
        }
      ]
    }
  )
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_gateway" {
  route_table_id  = aws_route_table.main.id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb_gateway.id
}

# SSM Interface
resource "aws_vpc_endpoint" "ssm_interface" {
  vpc_id            = var.common.network.vpc.id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.common.region}.ssm"
  subnet_ids = concat(
    [
      aws_subnet.support.id,
      aws_subnet.researcher.id
    ],
    aws_subnet.infrastructure[*].id
  )
  tags = {
    "Name" = "SSM Interface"
  }
}

resource "aws_vpc_endpoint_policy" "ssm_interface" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm_interface.id
  policy = jsonencode(
    {
      "Version" : "2008-10-17",
      "Statement" : [
        {
          "Sid" : "AllowAll",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "*",
          "Resource" : "*"
        }
      ]
    }
  )
}

# SQS Interface
resource "aws_vpc_endpoint" "sqs_interface" {
  vpc_id            = var.common.network.vpc.id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.common.region}.sqs"
  subnet_ids = concat(
    [
      aws_subnet.support.id,
      aws_subnet.researcher.id
    ],
    aws_subnet.infrastructure[*].id
  )
  tags = {
    "Name" = "SQS Interface"
  }
}

resource "aws_vpc_endpoint_policy" "sqs_interface" {
  vpc_endpoint_id = aws_vpc_endpoint.sqs_interface.id
  policy = jsonencode(
    {
      "Version" : "2008-10-17",
      "Statement" : [
        {
          "Sid" : "AllowAll",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "*",
          "Resource" : "*"
        }
      ]
    }
  )
}
