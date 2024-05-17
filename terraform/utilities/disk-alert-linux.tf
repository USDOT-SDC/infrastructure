locals {
  disk_alert_linux_script      = "disk-alert-linux.py"
  disk_alert_linux_script_path = "${basename(abspath(path.module))}/${local.disk_alert_linux_script}"
}

resource "aws_s3_object" "disk_alert_linux_script" {
  bucket = var.common.instance_maintenance_bucket.id
  key    = "infrastructure/${local.disk_alert_linux_script_path}"
  content = templatefile(
    "${local.disk_alert_linux_script_path}.tftpl",
    {
      endpoint_url  = "https://${var.research_teams_vpc_endpoint_lambda}/",
      email_address = var.common.admin_email
    }
  )
}

output "disk_alert_linux_script" {
  value = {
    bucket = aws_s3_object.disk_alert_linux_script.bucket,
    key    = aws_s3_object.disk_alert_linux_script.key
  }
}
