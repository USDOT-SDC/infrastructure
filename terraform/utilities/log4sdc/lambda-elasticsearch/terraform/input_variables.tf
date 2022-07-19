#
# Items with defaults
#

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "lambda_zip_path" {
  type = string
  default = "../src/"
}

variable "log_level" {
  type    = string
  default = "INFO"
  description = "Logging level for unified log4sdc facility"
}

variable "requests_aws4auth" {
  type = string
  description = "Name and version of the requests_aws4auth lambda layer for reuse"
}

#
# locals to be provided globally
#
locals {
  aws_region            = var.aws_region
  account_number        = "${data.aws_ssm_parameter.account_number.value}"
  environment           = "${data.aws_ssm_parameter.environment.value}"
  requests_aws4auth     = var.requests_aws4auth
  elasticsearch_url     = "${data.aws_ssm_parameter.elasticsearch_url.value}"
  log_level             = var.log_level

  global_tags = {
    "SourceRepo"  = "log4sdc"
    "Project"     = "SDC-Platform"
    "Team"        = "sdc-platform"
    "Environment" = "${data.aws_ssm_parameter.environment.value}"
    "Owner"       = "SDC support team"
  }
}

