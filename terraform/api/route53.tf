# === API Address Record ===
resource "aws_route53_record" "api" {
  name    = "api.${var.pub_fqdn}"
  type    = "A"
  zone_id = var.route53_zones.public.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.api.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api.cloudfront_zone_id
  }
}
