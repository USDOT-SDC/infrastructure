#!/bin/bash

# set $AWS_ACCOUNT_NUM as an environment variable
# prior to executing.
# Example (run on a command line of a linux box):
# export AWS_ACCOUNT_NUM=123456789
ACCOUNT_NUM=$AWS_ACCOUNT_NUM

ENVIRONMENT=dev

aws sns publish --topic-arn arn:aws:sns:us-east-1:${ACCOUNT_NUM}:${ENVIRONMENT}-log4sdc-alert-topic --subject "log4sdc-alert" --message "Test publish to log4sdc-alert-topic"
aws sns publish --topic-arn arn:aws:sns:us-east-1:${ACCOUNT_NUM}:${ENVIRONMENT}-log4sdc-error-topic --subject "log4sdc-error" --message "Test publish to log4sdc-error-topic"
aws sns publish --topic-arn arn:aws:sns:us-east-1:${ACCOUNT_NUM}:${ENVIRONMENT}-log4sdc-fatal-topic --subject "log4sdc-fatal" --message "Test publish to log4sdc-fatal-topic"

