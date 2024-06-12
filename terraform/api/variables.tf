variable "module_name" {}
variable "module_slug" {}
variable "common" {}
variable "aws_route53_zone" {}
variable "fqdn" {}
variable "certificates" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
  api_users      = toset(yamldecode(nonsensitive(data.aws_ssm_parameter.api_users.value)))
  api_token_name = "api_token"
  ecs_tags = { # ECS auto creates these tags. Putting them in Terraform will prevent config drift.
    "App Support" = "Jeff.Ussing.CTR"
    "Fed Owner"   = "Dan Morgan"
  }
}
