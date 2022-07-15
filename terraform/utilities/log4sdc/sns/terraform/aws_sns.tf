resource "aws_sns_topic" "log4sdc_error_topic" {
  #name = "${data.aws_ssm_parameter.environment.value}-log4sdc-error-topic"
  name = "${local.environment}-log4sdc-error-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "log4sdc_error_topic_policy" {
  arn = aws_sns_topic.log4sdc_error_topic.arn
  policy = templatefile("aws_sns_topic_policy_default.json", {
      #account_number         = "${data.aws_ssm_parameter.account_number.value}",
      account_number         = "${local.account_number}",
      topic_arn = aws_sns_topic.log4sdc_error_topic.arn
  })
}

resource "aws_sns_topic_subscription" "log4sdc_error_topic_subscription" {
  topic_arn = aws_sns_topic.log4sdc_error_topic.arn
  protocol  = "email"
  endpoint  = local.support_email
}


resource "aws_sns_topic" "log4sdc_critical_topic" {
  #name = "${data.aws_ssm_parameter.environment.value}-log4sdc-critical-topic"
  name = "${local.environment}-log4sdc-critical-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "log4sdc_critical_topic_policy" {
  arn = aws_sns_topic.log4sdc_critical_topic.arn
  policy = templatefile("aws_sns_topic_policy_default.json", {
      #account_number         = "${data.aws_ssm_parameter.account_number.value}",
      account_number         = "${local.account_number}",
      topic_arn = aws_sns_topic.log4sdc_critical_topic.arn
  })
}

resource "aws_sns_topic_subscription" "log4sdc_critical_topic_subscription" {
  topic_arn = aws_sns_topic.log4sdc_critical_topic.arn
  protocol  = "email"
  endpoint  = local.support_email
}

resource "aws_sns_topic_subscription" "log4sdc_critical_topic_subscription2" {
  topic_arn = aws_sns_topic.log4sdc_critical_topic.arn
  protocol  = "sms"
  endpoint  = local.support_sms_number
}

resource "aws_sns_topic" "log4sdc_alert_topic" {
  #name = "${data.aws_ssm_parameter.environment.value}-log4sdc-alert-topic"
  name = "${local.environment}-log4sdc-alert-topic"
  tags = local.global_tags
}

resource "aws_sns_topic_policy" "log4sdc_alert_topic_policy" {
  arn = aws_sns_topic.log4sdc_alert_topic.arn
  policy = templatefile("aws_sns_topic_policy_default.json", {
      #account_number         = "${data.aws_ssm_parameter.account_number.value}",
      account_number         = "${local.account_number}",
      topic_arn = aws_sns_topic.log4sdc_alert_topic.arn
  })
}

resource "aws_sns_topic_subscription" "log4sdc_alert_topic_subscription" {
  topic_arn = aws_sns_topic.log4sdc_alert_topic.arn
  protocol  = "email"
  endpoint  = local.support_email
}

resource "aws_ssm_parameter" "topic_arn_error" {
  name  = "/log4sdc/TOPIC_ARN_ERROR"
  type  = "String"
  value = aws_sns_topic.log4sdc_error_topic.arn
}

resource "aws_ssm_parameter" "topic_arn_critical" {
  name  = "/log4sdc/TOPIC_ARN_CRITICAL"
  type  = "String"
  value = aws_sns_topic.log4sdc_critical_topic.arn
}

resource "aws_ssm_parameter" "topic_arn_alert" {
  name  = "/log4sdc/TOPIC_ARN_ALERT"
  type  = "String"
  value = aws_sns_topic.log4sdc_alert_topic.arn
}

resource "aws_ssm_parameter" "log_level" {
  name  = "/log4sdc/LOG_LEVEL"
  type  = "String"
  value = "INFO"
}


# subscriptions and permissions - to go into lambda TFs
#
#resource "aws_sns_topic_subscription" "dot_sdc_metadata_ingestion_filter_lambda_subscription" {
#  topic_arn = aws_sns_topic.dot_sdc_raw_submissions_topic.arn
#  protocol  = "lambda"
#  endpoint  = aws_lambda_function.MetadataIngestionFilterLambda.arn
#}
#
#resource "aws_lambda_permission" "trigger_MetadataIngestionFilterLambda_with_sns" {
#    statement_id = "AllowExecutionFromSNS"
#    action = "lambda:InvokeFunction"
#    function_name = aws_lambda_function.MetadataIngestionFilterLambda.arn
#    principal = "sns.amazonaws.com"
#    source_arn = aws_sns_topic.dot_sdc_raw_submissions_topic.arn
#}


