
locals {
  environment           = "${data.aws_ssm_parameter.environment.value}"

  tags = {
    "Project"     = "SDC-Platform"
    "Team"        = "SDC-Platform"
    "Owner"       = "SDC Support Team"
  }
}

data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "../src"
    output_path = "instance-scheduler.zip"
}


data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda/lambda.zip"

  source {
    content  = "${path.module}/lambda/src/schedule.py"
    filename = "lambda_function.py"
  }

  source {
    content  = "${path.module}/lambda/venv/Lib/site-packages/pytz/*.*"
    filename = "pytz/*.*"
  }

  source {
    content  = "${path.module}/lambda/venv/Lib/site-packages/yaml/*.*"
    filename = "yaml/*.*"
  }
}

resource "aws_lambda_function" "instance-scheduler" {
    filename = "instance-scheduler.zip"
    function_name = "instance-scheduler"
    role = aws_iam_role.instance_scheduler_role.arn
    handler = "scheduler.lambda_handler"
    timeout = 30
    runtime = "python3.9"
    tags = local.tags
}

resource "aws_iam_role" "instance_scheduler_role" {
    name = "${local.environment}_instance_scheduler_role"
    assume_role_policy = file("assume_role_policy.json")
    tags = local.tags
}

resource "aws_iam_role_policy" "instance_scheduler_policy" {
    name="${local.environment}_instance_scheduler_policy"
    role = aws_iam_role.instance_scheduler_role.id
    policy = file("instance_scheduler_policy.json")
    tags = local.tags
}
