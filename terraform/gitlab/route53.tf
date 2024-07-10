# === GitLab Address Record ===
resource "aws_route53_record" "gitlab" {
  name    = "gitlab.${var.pri_fqdn}"
  type    = "A"
  ttl     = 300
  zone_id = var.route53_zones.private.zone_id
  records = [aws_instance.gitlab.private_ip]
}
