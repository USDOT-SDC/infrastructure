data "aws_ssm_parameter" "support_emails" {
  name = "/log4sdc/support_emails"
}

data "aws_ssm_parameter" "support_sms_numbers" {
  name = "/log4sdc/support_sms_numbers"
}

data "aws_ssm_parameter" "teams" {
  name = "/log4sdc/teams"
}

