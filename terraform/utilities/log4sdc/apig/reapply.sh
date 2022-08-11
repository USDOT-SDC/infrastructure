#!/bin/bash

APIG_MODULE=module.utilities.module.log4sdc.module.apig

##################
# log4sdc.sns
terraform apply -target=${APIG_MODULE}


