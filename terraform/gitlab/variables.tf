variable "module_name" {}
variable "module_slug" {}
variable "common" {}
variable "route53_zones" {}
variable "pri_fqdn" {}
variable "certificates" {}
variable "default_tags" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
}
