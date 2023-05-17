locals {
  tags = {
    Module = "instance-scheduler"
  }
  isl_path = "${path.module}/lambdas/instance-scheduler"
}

# === Build the Lambda deployment package ===
resource "terraform_data" "instance_scheduler_deploy_py" {
  triggers_replace = {
    lambda_function = filesha1("instance-scheduler/lambdas/instance-scheduler/lambda_function.py")
    requirements    = filesha1("instance-scheduler/lambdas/instance-scheduler/requirements.txt")
  }
  provisioner "local-exec" {
    command     = "python instance-scheduler/lambdas/instance-scheduler/deploy.py"
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
  }
}

resource "aws_lambda_function" "instance_scheduler" {
  function_name    = "instance-scheduler"
  filename         = "${local.isl_path}/deployment-package.zip"
  source_code_hash = fileexists("${local.isl_path}/deployment-package.zip") ? filebase64sha256("${local.isl_path}/deployment-package.zip") : timestamp()
  role             = aws_iam_role.instance_scheduler.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  depends_on       = [terraform_data.instance_scheduler_deploy_py]
  timeout          = "300"
  vpc_config {
    subnet_ids         = var.common.network.subnets
    security_group_ids = [var.common.network.default_security_group.id]
  }
  tags = local.tags
}

resource "aws_lambda_permission" "instance_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instance_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.instance_scheduler.arn # "arn:aws:events:eu-west-1:111122223333:rule/RunDaily"
}

/**
{
  Effect: "Allow",
  Action: "lambda:InvokeFunction",
  Resource: "arn:aws:lambda:region:account-id:function:function-name",
  "Principal": {
    "Service": "events.amazonaws.com"
  },
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:events:region:account-id:rule/rule-name"
    }
  },
  Sid: "InvokeLambdaFunction"
}
**/

resource "aws_iam_role" "instance_scheduler" {
  name = "instance_scheduler_role"
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
  tags = local.tags
}

resource "aws_iam_policy" "instance_scheduler" {
  name = "instance_scheduler_policy"
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

resource "aws_iam_policy_attachment" "instance_scheduler" {
  name       = "instance_scheduler_policy_attachment"
  roles      = [aws_iam_role.instance_scheduler.name]
  policy_arn = aws_iam_policy.instance_scheduler.arn
}

resource "aws_cloudwatch_event_rule" "instance_scheduler" {
  name                = "instance_scheduler"
  description         = "Triggers the instance-scheduler Lambda"
  schedule_expression = "cron(0 * * * ? *)" # at minute 0, every hour, day of the month, month, day of the week and year
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "instance_scheduler" {
  rule      = aws_cloudwatch_event_rule.instance_scheduler.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.instance_scheduler.arn
}

resource "aws_ssm_parameter" "Global_Schedule" {
  name        = "/Instance-Scheduler/Global-Schedule"
  description = "The Global Schedule for the instance-scheduler. All times are UTC."
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "Global_Schedule" {
  name = "/Instance-Scheduler/Global-Schedule"
  depends_on = [
    aws_ssm_parameter.Global_Schedule
  ]
}
