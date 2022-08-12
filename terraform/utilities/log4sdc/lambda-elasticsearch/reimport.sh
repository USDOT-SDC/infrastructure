#!/bin/bash

LAMBDA_ES_MODULE=module.utilities.module.log4sdc.module.lambda-elasticsearch

##################
# log4sdc.lambda-elasticsearch
terraform import ${LAMBDA_ES_MODULE}.aws_iam_role.log4sdc_es_publisher_role log4sdc-elasticsearch-publisher-role
terraform import ${LAMBDA_ES_MODULE}.aws_lambda_function.log4sdc_es_publisher log4sdc-elasticsearch-publisher

