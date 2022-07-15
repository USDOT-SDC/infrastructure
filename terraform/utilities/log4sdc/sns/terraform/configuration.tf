data "aws_ssm_parameter" "account_number" {
  name = "/common/secrets/account_number"
}

data "aws_ssm_parameter" "environment" {
  name = "/common/secrets/environment"
}

