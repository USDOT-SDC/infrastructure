#
# Items with defaults
#
variable "region" {
  type    = string
  default = "us-east-1"
}


#
# Items without defaults
#
variable "support_email" {
  type    = string
}


#
# locals to be provided globally
#
locals {
  account_id            = data.aws_caller_identity.current.account_id
  environment           = data.aws_ssm_parameter.environment.value
  support_email        = var.support_email

  global_tags = {
    "SourceRepo"  = "sdc-dot-cvp-metadata-ingestion"
    "Project"     = "SDC-Platform"
    "Team"        = "sdc-platform"
    "Environment" = data.aws_ssm_parameter.environment.value
    "Owner"       = "SDC support team"
  }
}
