#!/bin/bash

#terraform plan -target=module.utilities.module.log4sdc

#terraform plan -target=module.utilities.module.log4sdc.module.apig
terraform plan -target=module.utilities.module.log4sdc.module.lambda-elasticsearch
#terraform plan -target=module.utilities.module.log4sdc.module.sns


