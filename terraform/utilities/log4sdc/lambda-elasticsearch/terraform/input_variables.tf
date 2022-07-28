variable "common" {}
variable "default_tags" {}

#
# Items with defaults
#

variable "lambda_zip_path" {
  type = string
  default = "../src/"
}

variable "log_level" {
  type    = string
  default = "INFO"
  description = "Logging level for unified log4sdc facility"
}

#
# locals to be provided globally
#
locals {
  aws_region            = var.common.region
  account_number        = var.common.account_id 
  environment           = var.common.environment 
  requests_aws4auth     = data.aws_ssm_parameter.requests_aws4auth.value
  elasticsearch_url     = data.aws_ssm_parameter.elasticsearch_url.value
  log_level             = var.log_level

  global_tags = var.default_tags
}

