variable "common" {}
variable "default_tags" {}

locals {
  local_tags = {
    "Project"     = "SDC-Platform"
    "Team"        = "sdc-platform"
    "Environment" = var.common.environment
    "Owner"       = "SDC support team"
  }

  log4sdc_tags = merge(var.default_tags, local.local_tags)
}

