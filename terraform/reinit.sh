#!/bin/bash

echo "Use this bucket for backend:"
echo ${AWS_ENVIRONMENT}.sdc.dot.gov.platform.terraform

terraform init

