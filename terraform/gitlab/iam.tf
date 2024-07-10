# === IAM Role/Profile for EC2 Instance ===
resource "aws_iam_role" "gitlab" {
  name = "${var.common.configuration_slug}.gitlab"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : [
            "ec2.amazonaws.com"
          ]
        }
      }
    ]
  })
  inline_policy {
    name = "s3_access"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:PutObjectAcl"
          ],
          "Resource" : [
            "arn:aws:s3:::${var.common.backup_bucket.id}/*",
            "arn:aws:s3:::${var.common.environment}.sdc.dot.gov.platform.gitlab*/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts",
            "s3:ListBucketMultipartUploads"
          ],
          "Resource" : [
            "arn:aws:s3:::${var.common.backup_bucket.id}",
            "arn:aws:s3:::${var.common.environment}.sdc.dot.gov.platform.gitlab*"
          ]
        }
      ]
    })
  }
  tags = local.common_tags
}

resource "aws_iam_instance_profile" "gitlab" {
  name = aws_iam_role.gitlab.name
  role = aws_iam_role.gitlab.name
}
