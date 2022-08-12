#!/bin/bash

LAMBDA_ES_MODULE=module.utilities.module.log4sdc.module.lambda-elasticsearch

##################
# log4sdc.lambda-elasticsearch
terraform apply -target=${LAMBDA_ES_MODULE}


