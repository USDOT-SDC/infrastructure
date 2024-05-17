# === Variables to build the FQDN ===
variable "dev_fqdn" {
  default = "sdc-dev.dot.gov"
}

variable "prod_fqdn" {
  default = "sdc.dot.gov"
}

locals {
  fqdn = var.common.environment == "dev" ? var.dev_fqdn : var.prod_fqdn
}

# === API Address Record ===
resource "aws_route53_record" "api" {
  name    = "api.${local.fqdn}"
  type    = "A"
  zone_id = var.portal2_backend_route53_zone.public.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.api.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api.cloudfront_zone_id
  }
}
