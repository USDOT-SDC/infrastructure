resource "aws_s3_bucket" "backup" {
  bucket = local.common.backup_bucket
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

resource "aws_s3_bucket_acl" "backup" {
  bucket = aws_s3_bucket.backup.id
  acl    = "private"
  depends_on = [aws_s3_bucket.backup]
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.backup]
}
