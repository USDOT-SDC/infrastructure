data "archive_file" "lambda_deployment_package" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/deploy/lambda_deployment_package.zip"
}

resource "aws_lambda_function" "auto_start" {
  function_name    = "instance_auto_start"
  description      = "Function to start EC2 instances from a schedule"
  filename         = data.archive_file.lambda_deployment_package.output_path
  source_code_hash = data.archive_file.lambda_deployment_package.output_base64sha256
  role             = aws_iam_role.auto_start.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 6
  depends_on       = [data.archive_file.lambda_deployment_package]
  environment {
    variables = {
      ENV            = var.common.environment
      REGION         = var.common.region
      DYNAMODB_TABLE = aws_dynamodb_table.auto_start.name
    }
  }
  tags = local.tags
}

resource "aws_lambda_permission" "auto_start" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.auto_start.arn
}

resource "aws_iam_role" "auto_start" {
  name = "instance_auto_start_role"
  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          Effect : "Allow"
        }
      ]
    }
  )
  inline_policy {
    name = "instance_auto_start_policy"
    policy = jsonencode(
      {
        Version : "2012-10-17",
        Statement : [
          {
            Sid : "Parameters",
            Effect : "Allow",
            Action : "ssm:GetParameter",
            Resource : "*"
          },
          {
            Sid : "Buckets",
            Effect : "Allow",
            Action : "s3:*",
            Resource : "*"
          },
          {
            Sid : "Instances",
            Effect : "Allow",
            Action : "ec2:*",
            Resource : "*"
          },
          {
            Effect : "Allow",
            Action : [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:PutMetricFilter",
              "logs:PutRetentionPolicy"
            ],
            Resource : "*"
          }
        ]
      }
    )
  }
  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "auto_start" {
  name                = "auto_start"
  description         = "Triggers the instance_auto_start Lambda"
  schedule_expression = "cron(0 * * * ? *)" # at minute 0, every hour, day of the month, month, day of the week and year
  tags                = local.tags
}

# resource "aws_cloudwatch_event_target" "auto_start" {
#   rule      = aws_cloudwatch_event_rule.auto_start.name
#   target_id = "InvokeLambda"
#   arn       = aws_lambda_function.auto_start.arn
# }
