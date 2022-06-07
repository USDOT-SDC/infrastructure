#module "instance-scheduler" {
#  source                        = "./scheduler.py"
#  lambda_name                   = "instance-scheduler"
#  lambda_handler                = "instance-scheduler.lambda_handler"
#  aws_region                    = local.aws_region
#}

provider "aws" {
  region  = "us-east-1"
}

data "aws_ssm_parameter" "environment" {
  name = "/common/secrets/environment"
}

locals {
  environment           = "${data.aws_ssm_parameter.environment.value}"

  global_tags = {
    "SourceRepo"  = "instance-scheduler"
    "Project"     = "SDC-Platform"
    "Team"        = "sdc-platform"
    "Environment" = "${data.aws_ssm_parameter.environment.value}"
    "Owner"       = "SDC support team"
  }
}

data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "../src"
    output_path = "instance-scheduler.zip"
}

resource "aws_lambda_function" "instance-scheduler" {
    filename = "instance-scheduler.zip"
    function_name = "${local.environment}-dot-sdc-instance-scheduler"
    role = aws_iam_role.instance-schedule_role.arn
    handler = "scheduler.lambda_handler"
    timeout = 30
    runtime = "python3.8"

}

resource "aws_iam_role" "instance-schedule_role" {
    name = "${local.environment}-instance-schedule-role"
    assume_role_policy = file("assume_role_policy.json")
}

resource "aws_iam_role_policy" "instance-schedule_policy" {
    name="${local.environment}-instance-schedule-policy"
    role = aws_iam_role.instance-schedule_role.id
    policy = file("instance_scheduler_policy.json")
}
