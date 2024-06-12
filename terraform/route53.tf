# === Variables to build the FQDN and SOA Records ===
locals {
  dev_fqdn         = "sdc-dev.dot.gov"
  prod_fqdn        = "sdc.dot.gov"
  fqdn             = local.common.environment == "dev" ? local.dev_fqdn : local.prod_fqdn
  dev_soa_records  = ["${aws_route53_zone.public.name_servers[2]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
  prod_soa_records = ["${aws_route53_zone.public.name_servers[3]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
  soa_records      = local.common.environment == "dev" ? local.dev_soa_records : local.prod_soa_records
}

# === Public DNS Zone ===
resource "aws_route53_zone" "public" {
  name    = local.fqdn
  comment = "Hosted zone for DOT DNS to route any requests to *.${local.fqdn}; this is used for the portal and other resources."
  tags    = local.ecs_tags
}

# === Name Server Record ===
resource "aws_route53_record" "ns" {
  name            = local.fqdn
  allow_overwrite = true
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.public.zone_id
  records = toset(aws_route53_zone.public.name_servers[*])
}

# === Start of Authority Record ===
resource "aws_route53_record" "soa" {
  name            = local.fqdn
  allow_overwrite = true
  ttl             = 900
  type            = "SOA"
  zone_id         = aws_route53_zone.public.zone_id
  records         = local.soa_records
}
