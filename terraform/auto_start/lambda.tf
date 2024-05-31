locals {
  instance_auto_start_function_name = "instance_auto_start"
}
data "archive_file" "lambda_deployment_package" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/deploy/lambda_deployment_package.zip"
}

resource "aws_lambda_function" "auto_start" {
  function_name    = local.instance_auto_start_function_name
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
      ENV                   = var.common.environment
      REGION                = var.common.region
      DDBT_AUTO_START       = aws_dynamodb_table.auto_start.name
      DDBT_MAINTENANCE_WINDOW = aws_dynamodb_table.maintenance_windows.name
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
            Sid : "ReadOnlymaintenanceWindows",
            Effect : "Allow",
            Action : [
              "dynamodb:GetItem",
              "dynamodb:BatchGetItem",
              "dynamodb:Scan",
              "dynamodb:Query",
              "dynamodb:ConditionCheckItem"
            ],
            Resource : [
              aws_dynamodb_table.auto_start.arn,
              aws_dynamodb_table.maintenance_windows.arn,
            ]
          },
          {
            Sid : "DescribeStartInstances",
            Effect : "Allow",
            Action : [
              "ec2:DescribeInstances",
              "ec2:StartInstances"
            ]
            Resource : "arn:aws:ec2:*:*:instance/*"
          },
          {
            Sid : "CreateLogGroup"
            Effect : "Allow",
            Action : "logs:CreateLogGroup",
            Resource : "arn:aws:logs:region:${var.common.account_id}:*"
          },

          {
            Sid : "Logging"
            Effect : "Allow",
            Action : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            Resource : [
              "arn:aws:logs:region:${var.common.account_id}:log-group:/aws/lambda/${local.instance_auto_start_function_name}:*"
            ]
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
