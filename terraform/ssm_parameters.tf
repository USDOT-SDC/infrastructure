resource "aws_ssm_parameter" "account_id" {
  name        = "account_id"
  description = "The account_id of this account"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "account_id" {
  name = "account_id"
}

resource "aws_ssm_parameter" "region" {
  name        = "region"
  description = "The primary region of this account"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "region" {
  name = "region"
}

resource "aws_ssm_parameter" "environment" {
  name        = "environment"
  description = "The environment of this account"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "environment" {
  name = "environment"
}

resource "aws_ssm_parameter" "support_email" {
  name        = "support_email"
  description = "The Support Team's email"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "support_email" {
  name = "support_email"
}
