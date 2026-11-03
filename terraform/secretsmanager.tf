# === External domain certificate secrets ===
resource "aws_secretsmanager_secret" "certificate_external_private_key" {
  name                           = "/certificates/external/private_key"
  description                    = "Private key for the external domain certificate (unencrypted PEM — required by ACM)"
  force_overwrite_replica_secret = false
  recovery_window_in_days        = 30
  tags                           = local.default_tags
}

resource "aws_secretsmanager_secret_version" "certificate_external_private_key" {
  secret_id     = aws_secretsmanager_secret.certificate_external_private_key.id
  secret_string = file("${local.certificates_path}/external/${var.ext_fqdn}.key.plain")
}

resource "aws_secretsmanager_secret" "certificate_external_passphrase" {
  name                           = "/certificates/external/passphrase"
  description                    = "Passphrase used to encrypt the on-disk <CN>.key for the external domain certificate"
  force_overwrite_replica_secret = false
  recovery_window_in_days        = 30
  tags                           = local.default_tags
}

resource "aws_secretsmanager_secret_version" "certificate_external_passphrase" {
  secret_id     = aws_secretsmanager_secret.certificate_external_passphrase.id
  secret_string = file("${local.certificates_path}/external/${var.ext_fqdn}.passphrase.txt")
}

# === Internal domain certificate secrets ===
resource "aws_secretsmanager_secret" "certificate_internal_private_key" {
  name                           = "/certificates/internal/private_key"
  description                    = "Private key for the internal domain certificate (unencrypted PEM — required by ACM)"
  force_overwrite_replica_secret = false
  recovery_window_in_days        = 30
  tags                           = local.default_tags
}

resource "aws_secretsmanager_secret_version" "certificate_internal_private_key" {
  secret_id     = aws_secretsmanager_secret.certificate_internal_private_key.id
  secret_string = file("${local.certificates_path}/internal/${var.int_fqdn}.key.plain")
}

resource "aws_secretsmanager_secret" "certificate_internal_passphrase" {
  name                           = "/certificates/internal/passphrase"
  description                    = "Passphrase used to encrypt the on-disk <CN>.key for the internal domain certificate"
  force_overwrite_replica_secret = false
  recovery_window_in_days        = 30
  tags                           = local.default_tags
}

resource "aws_secretsmanager_secret_version" "certificate_internal_passphrase" {
  secret_id     = aws_secretsmanager_secret.certificate_internal_passphrase.id
  secret_string = file("${local.certificates_path}/internal/${var.int_fqdn}.passphrase.txt")
}

# === Internal AD domain certificate secrets ===
resource "aws_secretsmanager_secret" "certificate_internal_ad_private_key" {
  name                           = "/certificates/internal-ad/private_key"
  description                    = "Private key for the internal AD domain certificate (unencrypted PEM — required by ACM)"
  force_overwrite_replica_secret = false
  recovery_window_in_days        = 30
  tags                           = local.default_tags
}

resource "aws_secretsmanager_secret_version" "certificate_internal_ad_private_key" {
  secret_id     = aws_secretsmanager_secret.certificate_internal_ad_private_key.id
  secret_string = file("${local.certificates_path}/internal-ad/${var.int_ad_fqdn}.key.plain")
}

resource "aws_secretsmanager_secret" "certificate_internal_ad_passphrase" {
  name                           = "/certificates/internal-ad/passphrase"
  description                    = "Passphrase used to encrypt the on-disk <CN>.key for the internal AD domain certificate"
  force_overwrite_replica_secret = false
  recovery_window_in_days        = 30
  tags                           = local.default_tags
}

resource "aws_secretsmanager_secret_version" "certificate_internal_ad_passphrase" {
  secret_id     = aws_secretsmanager_secret.certificate_internal_ad_passphrase.id
  secret_string = file("${local.certificates_path}/internal-ad/${var.int_ad_fqdn}.passphrase.txt")
}
