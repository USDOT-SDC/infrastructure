# === Terraform Bucket ===
resource "aws_s3_bucket" "terraform" {
  bucket = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.terraform"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform" {
  bucket = aws_s3_bucket.terraform.bucket
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  depends_on = [aws_s3_bucket.terraform]
}

resource "aws_s3_bucket_ownership_controls" "terraform" {
  bucket = aws_s3_bucket.terraform.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [aws_s3_bucket.terraform]
}

resource "aws_s3_bucket_acl" "terraform" {
  bucket = aws_s3_bucket.terraform.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket.terraform,
    aws_s3_bucket_ownership_controls.terraform
  ]
}

resource "aws_s3_bucket_versioning" "terraform" {
  bucket = aws_s3_bucket.terraform.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.terraform]
}

# === Backup Bucket ===
resource "aws_s3_bucket" "backup" {
  bucket = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.backup"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.bucket
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  depends_on = [aws_s3_bucket.backup]
}

resource "aws_s3_bucket_ownership_controls" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [aws_s3_bucket.backup]
}

resource "aws_s3_bucket_acl" "backup" {
  bucket     = aws_s3_bucket.backup.id
  acl        = "private"
  depends_on = [
    aws_s3_bucket.backup,
    aws_s3_bucket_ownership_controls.backup
  ]
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.backup]
}

# === Instance Maintenance Bucket ===
resource "aws_s3_bucket" "instance_maintenance" {
  bucket = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.instance-maintenance"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "instance_maintenance" {
  bucket = aws_s3_bucket.instance_maintenance.bucket
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  depends_on = [aws_s3_bucket.instance_maintenance]
}

resource "aws_s3_bucket_ownership_controls" "instance_maintenance" {
  bucket = aws_s3_bucket.instance_maintenance.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [aws_s3_bucket.instance_maintenance]
}

resource "aws_s3_bucket_acl" "instance_maintenance" {
  bucket     = aws_s3_bucket.instance_maintenance.id
  acl        = "private"
  depends_on = [
    aws_s3_bucket.instance_maintenance,
    aws_s3_bucket_ownership_controls.instance_maintenance
  ]
}

resource "aws_s3_bucket_versioning" "instance_maintenance" {
  bucket = aws_s3_bucket.instance_maintenance.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.instance_maintenance]
}
