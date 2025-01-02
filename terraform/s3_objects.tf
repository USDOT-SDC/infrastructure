resource "aws_s3_object" "usdot_cer" {
  bucket      = aws_s3_bucket.secrets.bucket
  key         = "certs/USDOT/${local.common.environment}.sdc.cer"
  source      = "${local.certificates_path}/USDOT/${local.common.environment}.sdc.cer"
  source_hash = filemd5("${local.certificates_path}/USDOT/${local.common.environment}.sdc.cer")
}

resource "aws_s3_object" "usdot_p7b" {
  bucket      = aws_s3_bucket.secrets.bucket
  key         = "certs/USDOT/${local.common.environment}.sdc.p7b"
  source      = "${local.certificates_path}/USDOT/${local.common.environment}.sdc.p7b"
  source_hash = filemd5("${local.certificates_path}/USDOT/${local.common.environment}.sdc.p7b")
}
