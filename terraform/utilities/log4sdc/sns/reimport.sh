#!/bin/bash

# Set up the config file and uncomment the line below 
# to read sensitive vars
# . ~/log4sdc-env.sh

SNS_MODULE=module.utilities.module.log4sdc.module.sns

#terraform import aws_ssm_parameter.account_id account_id
#terraform import aws_ssm_parameter.admin_email admin_email
#terraform import aws_ssm_parameter.environment environment
#terraform import aws_ssm_parameter.region region
#terraform import aws_ssm_parameter.support_email support_email

##################
# log4sdc.sns
#terraform import ${SNS_MODULE}.aws_ssm_parameter.log_level /log4sdc/LOG_LEVEL

#terraform import ${SNS_MODULE}.aws_ssm_parameter.topic_arn_alert /log4sdc/TOPIC_ARN_ALERT
#terraform import ${SNS_MODULE}.aws_ssm_parameter.topic_arn_error /log4sdc/TOPIC_ARN_ERROR
#terraform import ${SNS_MODULE}.aws_ssm_parameter.topic_arn_critical /log4sdc/TOPIC_ARN_CRITICAL

#terraform import ${SNS_MODULE}.aws_sns_topic.log4sdc_alert_topic arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:${AWS_ENVIRONMENT}-log4sdc-alert-topic 
#terraform import ${SNS_MODULE}.aws_sns_topic.log4sdc_error_topic arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:${AWS_ENVIRONMENT}-log4sdc-error-topic 
#terraform import ${SNS_MODULE}.aws_sns_topic.log4sdc_critical_topic arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:${AWS_ENVIRONMENT}-log4sdc-critical-topic 


#terraform import ${SNS_MODULE}.aws_sns_topic_subscription.log4sdc_alert_topic_subscription arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:${AWS_ENVIRONMENT}-log4sdc-alert-topic:${Log4sdcAlertTopicSubUid}
#terraform import ${SNS_MODULE}.aws_sns_topic_subscription.log4sdc_error_topic_subscription arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:${AWS_ENVIRONMENT}-log4sdc-error-topic:${Log4sdcErrorTopicSubUid}
#terraform import ${SNS_MODULE}.aws_sns_topic_subscription.log4sdc_critical_topic_subscription arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:${AWS_ENVIRONMENT}-log4sdc-critical-topic:${Log4sdcCriticalTopicSubUid}
#terraform import ${SNS_MODULE}.aws_sns_topic_subscription.log4sdc_critical_topic_subscription2 arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:${AWS_ENVIRONMENT}-log4sdc-critical-topic:${Log4sdcCriticalTopicSub2Uid}

# Teams-relted import. For now: just demo account
terraform import ${SNS_MODULE}.aws_ssm_parameter.team_log_levels[\"acme\"] /log4sdc/acme/LOG_LEVEL

terraform import ${SNS_MODULE}.aws_ssm_parameter.team_topic_arn_alerts[\"acme\"] /log4sdc/acme/TOPIC_ARN_ALERT
terraform import ${SNS_MODULE}.aws_ssm_parameter.team_topic_arn_errors[\"acme\"] /log4sdc/acme/TOPIC_ARN_ERROR
terraform import ${SNS_MODULE}.aws_ssm_parameter.team_topic_arn_criticals[\"acme\"] /log4sdc/acme/TOPIC_ARN_CRITICAL


terraform import ${SNS_MODULE}.aws_sns_topic.team_alert_topics[\"acme\"] arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:acme-log4sdc-alert-topic
terraform import ${SNS_MODULE}.aws_sns_topic.team_error_topics[\"acme\"] arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:acme-log4sdc-error-topic
terraform import ${SNS_MODULE}.aws_sns_topic.team_critical_topics[\"acme\"] arn:aws:sns:us-east-1:${AWS_ACCOUNT_NUM}:acme-log4sdc-critical-topic


