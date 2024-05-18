resource "aws_ssm_parameter" "api_users" {
  name        = "/api/users"
  description = "SDC API Users (in yaml format)"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "api_users" {
  name = "/api/users"
  depends_on = [
    aws_ssm_parameter.api_users
  ]
}
