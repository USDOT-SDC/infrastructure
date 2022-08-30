resource "aws_sns_topic" "log4sdc_error_topic" {
  name = "log4sdc-error-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "log4sdc_error_topic_policy" {
  arn = aws_sns_topic.log4sdc_error_topic.arn
  policy = templatefile("utilities/log4sdc/sns/terraform/aws_sns_topic_policy_default.json", {
      account_number         = "${local.account_number}",
      topic_arn = aws_sns_topic.log4sdc_error_topic.arn
  })
}

resource "aws_sns_topic_subscription" "log4sdc_error_topic_subscription" {
  count     = length(local.support_emails)
  topic_arn = aws_sns_topic.log4sdc_error_topic.arn
  protocol  = "email"
  endpoint  = local.support_emails[count.index]
}


resource "aws_sns_topic" "log4sdc_critical_topic" {
  name = "log4sdc-critical-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "log4sdc_critical_topic_policy" {
  arn = aws_sns_topic.log4sdc_critical_topic.arn
  policy = templatefile("utilities/log4sdc/sns/terraform/aws_sns_topic_policy_default.json", {
      account_number         = "${local.account_number}",
      topic_arn = aws_sns_topic.log4sdc_critical_topic.arn
  })
}

resource "aws_sns_topic_subscription" "log4sdc_critical_topic_subscription" {
  count     = length(local.support_emails)
  topic_arn = aws_sns_topic.log4sdc_critical_topic.arn
  protocol  = "email"
  endpoint  = local.support_emails[count.index]
}

resource "aws_sns_topic_subscription" "log4sdc_critical_topic_subscription2" {
  count     = length(local.support_sms_numbers)
  topic_arn = aws_sns_topic.log4sdc_critical_topic.arn
  protocol  = "sms"
  endpoint  = local.support_sms_numbers[count.index]
}

resource "aws_sns_topic" "log4sdc_alert_topic" {
  name = "log4sdc-alert-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "log4sdc_alert_topic_policy" {
  arn = aws_sns_topic.log4sdc_alert_topic.arn
  policy = templatefile("utilities/log4sdc/sns/terraform/aws_sns_topic_policy_default.json", {
      account_number         = "${local.account_number}",
      topic_arn = aws_sns_topic.log4sdc_alert_topic.arn
  })
}

resource "aws_sns_topic_subscription" "log4sdc_alert_topic_subscription" {
  count     = length(local.support_emails)
  topic_arn = aws_sns_topic.log4sdc_alert_topic.arn
  protocol  = "email"
  endpoint  = local.support_emails[count.index]
}

resource "aws_ssm_parameter" "topic_arn_error" {
  name  = "/log4sdc/TOPIC_ARN_ERROR"
  type  = "String"
  value = aws_sns_topic.log4sdc_error_topic.arn
  tags = local.global_tags
}

resource "aws_ssm_parameter" "topic_arn_critical" {
  name  = "/log4sdc/TOPIC_ARN_CRITICAL"
  type  = "String"
  value = aws_sns_topic.log4sdc_critical_topic.arn
  tags = local.global_tags
}

resource "aws_ssm_parameter" "topic_arn_alert" {
  name  = "/log4sdc/TOPIC_ARN_ALERT"
  type  = "String"
  value = aws_sns_topic.log4sdc_alert_topic.arn
  tags = local.global_tags
}

resource "aws_ssm_parameter" "log_level" {
  name  = "/log4sdc/LOG_LEVEL"
  type  = "String"
  value = "INFO"
  tags = local.global_tags
}

