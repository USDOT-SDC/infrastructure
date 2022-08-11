#!/bin/bash

SNS_MODULE=module.utilities.module.log4sdc.module.sns

##################
# log4sdc.sns
terraform apply -target=${SNS_MODULE}


