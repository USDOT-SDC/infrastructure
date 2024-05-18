variable "module_name" {}
variable "module_slug" {}
variable "common" {}
variable "portal2_backend_route53_zone" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
  api_token_name = "api_token"
  ecs_tags = { # ECS auto creates these tags. Putting them in Terraform will prevent config drift.
    "App Support" = "Jeff.Ussing.CTR"
    "Fed Owner"   = "Dan Morgan"
  }

}
