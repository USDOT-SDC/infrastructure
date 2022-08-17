# Knowledge base: 
# https://medium.com/swlh/terraform-iterating-through-a-map-of-lists-to-define-aws-roles-and-permissions-a6d434182114
# ERROR
resource "aws_sns_topic" "team_error_topics" {
  for_each = local.teams
  name = "${each.key}-log4sdc-error-topic"
  display_name = "${each.key}-log4sdc-error-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "team_error_topic_policies" {
  for_each = local.teams

  arn = aws_sns_topic.team_error_topics[each.key].arn
  policy = templatefile("utilities/log4sdc/sns/terraform/aws_sns_topic_policy_default.json", {
      account_number         = local.account_number,
      topic_arn = aws_sns_topic.team_error_topics[each.key].arn
  })
}

resource "aws_sns_topic_subscription" "team_error_topic_subscription" {
  for_each = {
    for elt in local.emails_by_team : "${elt.team_name}.${elt.email}" => elt
  }

  topic_arn = aws_sns_topic.team_error_topics[each.value.team_name].arn
  protocol  = "email"
  endpoint  = each.value.email
}


# CRITICAL
resource "aws_sns_topic" "team_critical_topics" {
  for_each = local.teams
  name = "${each.key}-log4sdc-critical-topic"
  display_name = "${each.key}-log4sdc-critical-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "team_critical_topic_policies" {
  for_each = local.teams

  arn = aws_sns_topic.team_critical_topics[each.key].arn
  policy = templatefile("utilities/log4sdc/sns/terraform/aws_sns_topic_policy_default.json", {
      account_number         = local.account_number,
      topic_arn = aws_sns_topic.team_critical_topics[each.key].arn
  })
}

resource "aws_sns_topic_subscription" "team_critical_topic_subscription" {
  for_each = {
    for elt in local.emails_by_team : "${elt.team_name}.${elt.email}" => elt
  }

  topic_arn = aws_sns_topic.team_critical_topics[each.value.team_name].arn
  protocol  = "email"
  endpoint  = each.value.email
}

resource "aws_sns_topic_subscription" "team_critical_topic_subscription2" {
  for_each = {
    for elt in local.sms_numbers_by_team : "${elt.team_name}.${elt.sms_number}" => elt
  }

  topic_arn = aws_sns_topic.team_critical_topics[each.value.team_name].arn
  protocol  = "sms"
  endpoint  = each.value.sms_number
}


# ALERT
resource "aws_sns_topic" "team_alert_topics" {
  #count = local.create_team_sns_topics && length(local.team_names) > 0 ? length(local.team_names) : 0
 
  for_each = local.teams
  name = "${each.key}-log4sdc-alert-topic"
  display_name = "${each.key}-log4sdc-alert-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "team_alert_topic_policies" {
  for_each = local.teams

  arn = aws_sns_topic.team_alert_topics[each.key].arn
  policy = templatefile("utilities/log4sdc/sns/terraform/aws_sns_topic_policy_default.json", {
      account_number         = local.account_number,
      topic_arn = aws_sns_topic.team_alert_topics[each.key].arn
  })
}

resource "aws_sns_topic_subscription" "team_alert_topic_subscription" {
  for_each = {
    for elt in local.emails_by_team : "${elt.team_name}.${elt.email}" => elt
  }

  topic_arn = aws_sns_topic.team_alert_topics[each.value.team_name].arn
  protocol  = "email"
  endpoint  = each.value.email
}

# SSM Parameters for teams
resource "aws_ssm_parameter" "team_topic_arn_errors" {
  for_each = local.teams
  name  = "/log4sdc/${each.key}/TOPIC_ARN_ERROR"
  type  = "String"
  value = aws_sns_topic.team_error_topics["${each.key}"].arn
  tags = local.global_tags
}

resource "aws_ssm_parameter" "team_topic_arn_criticals" {
  for_each = local.teams
  name  = "/log4sdc/${each.key}/TOPIC_ARN_CRITICAL"
  type  = "String"
  value = aws_sns_topic.team_critical_topics["${each.key}"].arn
  tags = local.global_tags
}

resource "aws_ssm_parameter" "team_topic_arn_alerts" {
  for_each = local.teams
  name  = "/log4sdc/${each.key}/TOPIC_ARN_ALERT"
  type  = "String"
  value = aws_sns_topic.team_alert_topics["${each.key}"].arn
  tags = local.global_tags
}

resource "aws_ssm_parameter" "team_log_levels" {
  for_each = local.teams
  name  = "/log4sdc/${each.key}/LOG_LEVEL"
  type  = "String"
  value = "INFO"
  tags = local.global_tags
}


