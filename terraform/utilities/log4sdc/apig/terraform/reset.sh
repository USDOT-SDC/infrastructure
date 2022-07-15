#!/bin/bash

rm -rf .terraform
aws s3 rm s3://${AWS_ENVIRONMENT}.sdc.dot.gov.platform.terraform/log4sdc/apig/terraform/ --recursive

