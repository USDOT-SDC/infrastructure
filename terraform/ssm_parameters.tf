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
  depends_on = [
    aws_ssm_parameter.account_id
  ]
}

resource "aws_ssm_parameter" "account_id_dev" {
  name        = "account_id_dev"
  description = "The account_id of the dev account"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "account_id_dev" {
  name = "account_id_dev"
  depends_on = [
    aws_ssm_parameter.account_id_dev
  ]
}

resource "aws_ssm_parameter" "account_id_prod" {
  name        = "account_id_prod"
  description = "The account_id of the prod account"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "account_id_prod" {
  name = "account_id_prod"
  depends_on = [
    aws_ssm_parameter.account_id_prod
  ]
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
  depends_on = [
    aws_ssm_parameter.region
  ]
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
  depends_on = [
    aws_ssm_parameter.environment
  ]
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
  depends_on = [
    aws_ssm_parameter.support_email
  ]
}

resource "aws_ssm_parameter" "admin_email" {
  name        = "admin_email"
  description = "The Admin Team's email"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "admin_email" {
  name = "admin_email"
  depends_on = [
    aws_ssm_parameter.admin_email
  ]
}
