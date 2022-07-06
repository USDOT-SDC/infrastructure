variable "common" {}

locals {
  module = basename(abspath(path.module))
  tags = {
    "Project" = "SDC-Platform"
    "Team"    = "SDC-Platform"
    "Owner"   = "SDC Support Team"
    "Module"  = local.module
  }
}
