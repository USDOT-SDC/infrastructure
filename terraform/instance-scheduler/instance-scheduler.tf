locals {
  tags = {
    "Project" = "SDC-Platform"
    "Team"    = "SDC-Platform"
    "Owner"   = "SDC Support Team"
  }
  isl_path = "${path.module}/lambdas/instance-scheduler"
}

# === Build the Lambda deployment package ===
resource "null_resource" "run-deploy" {
  triggers = {
    timestamp = timestamp()
  }
  provisioner "local-exec" {
    command     = "python instance-scheduler/lambdas/instance-scheduler/deploy.py"
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
  }
}

resource "aws_lambda_function" "instance-scheduler" {
  function_name    = "instance-scheduler"
  filename         = "${local.isl_path}/deployment-package.zip"
  source_code_hash = fileexists("${local.isl_path}/deployment-package.zip") ? filebase64sha256("${local.isl_path}/deployment-package.zip") : timestamp()
  role             = aws_iam_role.instance_scheduler_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  depends_on       = [null_resource.run-deploy]
  timeout          = "300"
  vpc_config {
    subnet_ids         = var.common.network.subnets.ids
    security_group_ids = [var.common.network.default_security_group.id]
  }
  tags = local.tags
}

resource "aws_iam_role" "instance_scheduler_role" {
  name               = "instance_scheduler_role"
  assume_role_policy = file("instance-scheduler/instance_scheduler_role.json")
  tags               = local.tags
}

resource "aws_iam_role_policy" "instance_scheduler_policy" {
  name   = "instance_scheduler_policy"
  role   = aws_iam_role.instance_scheduler_role.id
  policy = file("instance-scheduler/instance_scheduler_policy.json")
}

resource "aws_cloudwatch_event_rule" "instance_scheduler" {
  name                = "instance_scheduler"
  description         = "Triggers the ${aws_lambda_function.instance-scheduler.function_name} Lambda"
  schedule_expression = "rate(1 hour)" # at minute 0, every hour, day of the month, month, day of the week
  tags = local.tags
}

resource "aws_cloudwatch_event_target" "instance_scheduler_lambda" {
  rule      = aws_cloudwatch_event_rule.instance_scheduler.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.instance-scheduler.arn
}
