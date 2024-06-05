locals {
  instance_auto_start_function_name = "instance_auto_start"
  source_dir                        = "${path.module}/src/"
  # everything                        = fileset("${local.source_dir}/", "**/*")
  exclude_venv          = fileset("${local.source_dir}/", ".venv/**/*")
  exclude_pycache       = fileset("${local.source_dir}/", "__pycache__/**/*")
  exclude_croniter_info = fileset("${local.source_dir}/", "croniter-*/**/*")
  exclude_pytz_info     = fileset("${local.source_dir}/", "pytz-*/**/*")
  excludes = setunion(
    local.exclude_venv,
    local.exclude_pycache,
    local.exclude_croniter_info,
    local.exclude_pytz_info,
    [
      ".gitignore",
      "dev-test-event.json",
      "dev-test.py",
      "README.md",
      "requirements-deployment-package.txt",
      "requirements.txt",
      "sandbox.py",
    ]
  )
}

# this zip file will only build correctly after following instructions in src\README.md
data "archive_file" "lambda_deployment_package" {
  type        = "zip"
  output_path = "${path.module}/deploy/lambda_deployment_package.zip"
  source_dir  = local.source_dir
  excludes    = local.excludes
}

resource "aws_lambda_function" "auto_start" {
  function_name    = local.instance_auto_start_function_name
  description      = "Function to start EC2 instances from a schedule"
  filename         = data.archive_file.lambda_deployment_package.output_path
  source_code_hash = data.archive_file.lambda_deployment_package.output_base64sha256
  role             = aws_iam_role.auto_start.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  depends_on       = [data.archive_file.lambda_deployment_package]
  logging_config {
    log_group  = aws_cloudwatch_log_group.auto_start.name
    log_format = "Text"
  }
  environment {
    variables = {
      ENV                     = var.common.environment
      REGION                  = var.common.region
      DDBT_AUTO_START         = aws_dynamodb_table.auto_start.name
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
            Sid : "ReadOnlyDynamoDB",
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
            Resource : "*"
          },
          {
            Sid : "CreateLogGroup"
            Effect : "Allow",
            Action : "logs:CreateLogGroup",
            Resource : "arn:aws:logs:${var.common.region}:${var.common.account_id}:*"
          },

          {
            Sid : "Logging"
            Effect : "Allow",
            Action : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            Resource : [
              "arn:aws:logs:${var.common.region}:${var.common.account_id}:log-group:/aws/lambda/${local.instance_auto_start_function_name}:*"
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
  schedule_expression = "cron(0/15 * * * ? *)" 
                        # at minute 0/every 15 minutes, every hour, day of the month, month, day of the week and year
                        # (Min Hr DoM M DoW Y)
                        # You can't use * in both the Day-of-month and Day-of-week fields. 
                        # If you use it in one, you must use ? in the other.
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "auto_start" {
  rule      = aws_cloudwatch_event_rule.auto_start.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.auto_start.arn
}

resource "aws_cloudwatch_log_group" "auto_start" {
  name              = "/aws/lambda/instance_auto_start"
  skip_destroy      = "true"
  retention_in_days = 180
}
