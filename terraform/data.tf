data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "account_id" {
  name = "account_id"
}

data "aws_ssm_parameter" "environment" {
  name = "environment"
}
