variable "common" {}
variable "default_tags" {}

#
# locals to be provided globally
#
locals {
  account_number        = var.common.account_id
  environment        = var.common.environment
  support_email        = var.common.admin_email
  support_sms_number        = data.aws_ssm_parameter.support_sms_number.value

  global_tags = var.default_tags
}
