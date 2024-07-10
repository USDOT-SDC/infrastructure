# === Variables to build the Public FQDN and SOA Records ===
locals {
  dev_pub_fqdn         = "sdc-dev.dot.gov"
  prod_pub_fqdn        = "sdc.dot.gov"
  pub_fqdn             = local.common.environment == "dev" ? local.dev_pub_fqdn : local.prod_pub_fqdn
  dev_pub_soa_records  = ["${aws_route53_zone.public.name_servers[2]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
  prod_pub_soa_records = ["${aws_route53_zone.public.name_servers[3]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
  pub_soa_records      = local.common.environment == "dev" ? local.dev_pub_soa_records : local.prod_pub_soa_records
}

# ---- Public DNS Zone ----
resource "aws_route53_zone" "public" {
  name    = local.pub_fqdn
  comment = "Hosted zone for DOT DNS to route any requests to *.${local.pub_fqdn}; this is used for the portal and other resources."
  tags    = local.ecs_tags
}

# ---- Public Name Server Record ----
resource "aws_route53_record" "public_ns" {
  name            = local.pub_fqdn
  allow_overwrite = true
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.public.zone_id
  records         = toset(aws_route53_zone.public.name_servers[*])
}

# ---- Public Start of Authority Record ----
resource "aws_route53_record" "public_soa" {
  name            = local.pub_fqdn
  allow_overwrite = true
  ttl             = 900
  type            = "SOA"
  zone_id         = aws_route53_zone.public.zone_id
  records         = local.pub_soa_records
}

# === Variables to build the Private FQDN and SOA Records ===
locals {
  pri_fqdn             = "${local.common.environment}.sdc.dot.gov"
  dev_pri_soa_records  = ["${aws_route53_zone.private.name_servers[2]} awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
  prod_pri_soa_records = ["${aws_route53_zone.private.name_servers[3]} awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
  pri_soa_records      = local.common.environment == "dev" ? local.dev_pri_soa_records : local.prod_pri_soa_records
}

# ---- Private DNS Zone ----
resource "aws_route53_zone" "private" {
  name    = local.pri_fqdn
  comment = "Hosted zone for DOT DNS to route any requests to *.${local.pri_fqdn}; this is used for internal resources."
  vpc {
    vpc_id     = local.common.network.vpc.id
    vpc_region = local.common.region
  }
  tags = local.ecs_tags
}

# ---- Private Name Server Record ----
resource "aws_route53_record" "private_ns" {
  name            = local.pri_fqdn
  allow_overwrite = true
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.private.zone_id
  records         = toset(aws_route53_zone.private.name_servers[*])
}

# ---- Private Start of Authority Record ----
resource "aws_route53_record" "private_soa" {
  name            = local.pri_fqdn
  allow_overwrite = true
  ttl             = 900
  type            = "SOA"
  zone_id         = aws_route53_zone.private.zone_id
  records         = local.pri_soa_records
}
