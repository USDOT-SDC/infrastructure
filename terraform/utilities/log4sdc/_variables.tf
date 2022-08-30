variable "common" {}
variable "default_tags" {}

locals {
  local_tags = {
    Module = "utilities/log4sdc"
  }
  log4sdc_tags = local.local_tags
}
