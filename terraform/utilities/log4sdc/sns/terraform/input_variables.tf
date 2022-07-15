#
# Items with defaults
#


#
# Items without defaults
#
variable "support_email" {
  type    = string
}

variable "support_sms_number" {
  type    = string
}


#
# locals to be provided globally
#
locals {
  account_number        = "${data.aws_ssm_parameter.account_number.value}"
  environment        = "${data.aws_ssm_parameter.environment.value}"
  support_email        = var.support_email
  support_sms_number        = var.support_sms_number

  global_tags = {
    "SourceRepo"  = "sdc-dot-cvp-metadata-ingestion"
    "Project"     = "SDC-Platform"
    "Team"        = "sdc-platform"
    "Environment" = "${data.aws_ssm_parameter.environment.value}"
    "Owner"       = "SDC support team"
  }
}
