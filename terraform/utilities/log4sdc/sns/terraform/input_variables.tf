variable "common" {}
variable "default_tags" {}

#
# locals to be provided globally
#
locals {
  account_number        = var.common.account_id
  environment        = var.common.environment
  support_emails        = nonsensitive(jsondecode(data.aws_ssm_parameter.support_emails.value))
  support_sms_numbers        = nonsensitive(jsondecode(data.aws_ssm_parameter.support_sms_numbers.value))

  teams              = nonsensitive(jsondecode(data.aws_ssm_parameter.teams.value))

  global_tags = var.default_tags

  emails_by_team = flatten([
    for team, val in local.teams : [
      for subscriber_email in val.emails : {
        team_name = team
        email = subscriber_email
      }
    ] 
  ])

  sms_numbers_by_team = flatten([
    for team, val in local.teams : [
      for subscriber_sms_number in val.sms_numbers : {
        team_name = team
        sms_number = subscriber_sms_number
      }
    ] 
  ])
}
