# This cert is used for external facing resources; portal, api, etc.
# domain name: sdc{-dev}.dot.gov
# domains:  www.sdc{-dev}.dot.gov, portal.sdc{-dev}.dot.gov, portal-api.sdc{-dev}.dot.gov,
#           guacamole.sdc{-dev}.dot.gov, api.sdc{-dev}.dot.gov, sftp.sdc{-dev}.dot.gov,
#           sub1.sdc{-dev}.dot.gov, sub2.sdc{-dev}.dot.gov
data "aws_secretsmanager_secret_version" "certificate_external_private_key" {
  secret_id  = aws_secretsmanager_secret.certificate_external_private_key.id
  depends_on = [aws_secretsmanager_secret_version.certificate_external_private_key]
}

resource "aws_acm_certificate" "external" {
  private_key       = data.aws_secretsmanager_secret_version.certificate_external_private_key.secret_string
  certificate_body  = file("${local.certificates_path}/external/Server.pem")
  certificate_chain = file("${local.certificates_path}/external/Intermediate.pem")
  tags = merge(
    local.default_tags,
    { Name = var.ext_fqdn }
  )
}

# This cert is used for internal facing resources; GitLab, etc.
# domain name: {dev/prod}.sdc.dot.gov
# domains:  gitlab.{dev/prod}.sdc.dot.gov, guacamole.{dev/prod}.sdc.dot.gov,
#           sub1.{dev/prod}.sdc.dot.gov, sub2.{dev/prod}.sdc.dot.gov,
data "aws_secretsmanager_secret_version" "certificate_internal_private_key" {
  secret_id  = aws_secretsmanager_secret.certificate_internal_private_key.id
  depends_on = [aws_secretsmanager_secret_version.certificate_internal_private_key]
}

resource "aws_acm_certificate" "internal" {
  private_key       = data.aws_secretsmanager_secret_version.certificate_internal_private_key.secret_string
  certificate_body  = file("${local.certificates_path}/internal/Server.pem")
  certificate_chain = file("${local.certificates_path}/internal/Intermediate.pem")
  tags = merge(
    local.default_tags,
    { Name = var.int_fqdn }
  )
}

# This cert is used for internal AD facing resources; GitLab, etc.
# domain name: {dev-ad/prod-ad}.sdc.dot.gov
# domains:  gitlab.{dev-ad/prod-ad}.sdc.dot.gov,
#           sub1.{dev-ad/prod-ad}.sdc.dot.gov, sub2.{dev-ad/prod-ad}.sdc.dot.gov,
data "aws_secretsmanager_secret_version" "certificate_internal_ad_private_key" {
  secret_id  = aws_secretsmanager_secret.certificate_internal_ad_private_key.id
  depends_on = [aws_secretsmanager_secret_version.certificate_internal_ad_private_key]
}

resource "aws_acm_certificate" "internal_ad" {
  private_key       = data.aws_secretsmanager_secret_version.certificate_internal_ad_private_key.secret_string
  certificate_body  = file("${local.certificates_path}/internal-ad/Server.pem")
  certificate_chain = file("${local.certificates_path}/internal-ad/Intermediate.pem")
  tags = merge(
    local.default_tags,
    { Name = var.int_ad_fqdn }
  )
}
