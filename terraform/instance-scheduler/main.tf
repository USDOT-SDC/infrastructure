locals {
  tags = {
    "Project" = "SDC-Platform"
    "Team"    = "SDC-Platform"
    "Owner"   = "SDC Support Team"
  }
}

resource "null_resource" "copy_pytz" {
  provisioner "file" {
    source      = "${path.module}/lambda/venv/Lib/site-packages/pytz/"
    destination = "${path.module}/lambda/src/pytz/"
  }
}

resource "null_resource" "copy_yaml" {
  provisioner "file" {
    source      = "${path.module}/lambda/venv/Lib/site-packages/yaml/"
    destination = "${path.module}/lambda/src/yaml/"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/"
  output_path = "${path.module}/lambda/lambda.zip"
  depends_on = [
    null_resource.copy_pytz,
    null_resource.copy_yaml
  ]
}

resource "aws_lambda_function" "instance-scheduler" {
  filename      = "${path.module}/lambda/lambda.zip"
  function_name = "instance-scheduler"
  role          = aws_iam_role.instance_scheduler_role.arn
  handler       = "scheduler.lambda_handler"
  runtime       = "python3.9"
  depends_on = [
    data.archive_file.lambda
  ]
  tags = local.tags
}

resource "aws_iam_role" "instance_scheduler_role" {
  name               = "instance_scheduler_role"
  assume_role_policy = file("instance-scheduler/assume_role_policy.json")
  tags               = local.tags
}

resource "aws_iam_role_policy" "instance_scheduler_policy" {
  name   = "instance_scheduler_policy"
  role   = aws_iam_role.instance_scheduler_role.id
  policy = file("instance-scheduler/instance_scheduler_policy.json")
}
