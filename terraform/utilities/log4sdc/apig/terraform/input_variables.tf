#
# Root common variables
#
variable "common" {}
variable "default_tags" {}

#
# locals to be provided globally
#
locals {
  account_id            = var.common.account_id
  environment           = var.common.environment
  region                = var.common.region
  admin_email           = var.common.admin_email

  global_tags = var.default_tags
}
