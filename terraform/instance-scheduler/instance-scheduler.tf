locals {
  tags = {
    "Project" = "SDC-Platform"
    "Team"    = "SDC-Platform"
    "Owner"   = "SDC Support Team"
  }
  isl_path = "${path.module}/lambdas/instance-scheduler"
}

# === Build the Lambda deployment package ===
# Delete last deployment package
# Remove-Item -Recurse -Force some_dir
resource "null_resource" "delete-deployment-package" {
  triggers = {
    timestamp = timestamp()
  }
  provisioner "local-exec" {
    command = "rm -r -fo \"${local.isl_path}/deployment-package\""
  }
}
# Create the venv
resource "null_resource" "venv" {
  triggers = {
    timestamp = timestamp()
  }
  provisioner "local-exec" {
    command = "python -m venv ${local.isl_path}/venv --prompt instance-scheduler"
  }
}
# Copy the script
resource "null_resource" "copy_lambda_function" {
  provisioner "local-exec" {
    # Copy-Item "C:\Wabash\Logfiles\mar1604.log.txt" -Destination "C:\Presentation"
    command     = "Copy-Item \"${local.isl_path}/lambda_function.py\" -Destination \"${local.isl_path}/deployment-package\""
    interpreter = ["PowerShell", "-Command"]
  }
  triggers = {
    timestamp = timestamp()
  }
}
# Copy packages NOT included in the Lambda runtime
resource "null_resource" "copy_pytz" {
  provisioner "local-exec" {
    command     = "Copy-Item -Path \"${local.isl_path}/venv/Lib/site-packages/pytz\" -Destination \"${local.isl_path}/deployment-package\" -Recurse"
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [null_resource.venv]
  triggers = {
    timestamp = timestamp()
  }
}
resource "null_resource" "copy_yaml" {
  provisioner "local-exec" {
    command     = "Copy-Item -Path \"${local.isl_path}/venv/Lib/site-packages/yaml\" -Destination \"${local.isl_path}/deployment-package\" -Recurse"
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [null_resource.venv]
  triggers = {
    timestamp = timestamp()
  }
}
# Create the deployment package
data "archive_file" "instance-scheduler-deployment-package" {
  type             = "zip"
  source_dir       = "${local.isl_path}/deployment-package/"
  output_path      = "${local.isl_path}/deployment-package.zip"
  output_file_mode = "0666"
  depends_on = [
    null_resource.venv,
    null_resource.copy_lambda_function,
    null_resource.copy_pytz,
    null_resource.copy_yaml
  ]
}

resource "aws_lambda_function" "instance-scheduler" {
  function_name    = "instance-scheduler"
  filename         = "${local.isl_path}/deployment-package.zip"
  source_code_hash = filebase64sha256("${local.isl_path}/deployment-package.zip")
  role             = aws_iam_role.instance_scheduler_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  depends_on = [
    data.archive_file.instance-scheduler-deployment-package
  ]
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
