variable "module_name" {}
variable "module_slug" {}
variable "common" {}
locals {
  common_tags = {
    "module" = var.module_slug
  }
}
