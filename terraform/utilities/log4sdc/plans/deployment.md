# Deployment Plan

## Deployment Build Environment
- Windows or Linux
- AWS CLI [version 2.1.39](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- Terraform [v0.12.26](https://releases.hashicorp.com/terraform/0.12.26/)
- AWS Provider [2.70.0](https://registry.terraform.io/providers/hashicorp/aws/2.70.0)

## Prerequisite

Lambda layer requests_aws4auth should be present in the environment. Distribution archive is located in s3://<lambda bin bucket>/requests_aws4auth/

## Deployment of [v1.2](https://github.com/USDOT-SDC/log4sdc/tree/1.2)

* Clone the log4sdc repository into a Linux environment (e.g., SDC build machine)
* Change to the log4sdc folder

### SNS Topic deployment
* Change to the sns/terraform folder
  * cd sns/terraform
* Execute the following commands to deploy the updates:
  * terraform init -var-file=config/backend-ecs-prod.tfvars
  * terraform apply -var-file=config/ecs-prod.tfvars

### Log4sdc lambda layer deployment
* Change to the lambda-layer/deploy folder
  * cd lambda-layer/deploy
* Execute the following command to deploy the lambda layer:
  * ./deploy-common-layer.sh

### ElasticSearch publisher lambda function deployment
* Change to the lambda-elasticsearch/terraform folder
  * cd lambda-elasticsearch/terraform
* Execute the following commands to deploy the updates:
  * terraform init -var-file=config/backend-ecs-prod.tfvars
  * terraform apply -var-file=config/ecs-prod.tfvars

### ElasticSearch index and index pattern deployment
* Log on into AWS console
* Navigate to OpenSearch Kibana interface
* Open Dev Tools section
* Copy/paste content of elasticsearch/log4sdc-index.put file into Dev Tools console
* Execute the pasted statement
* Navigate to Management section
* Navigate to Index Patterns
* Execute "Create index pattern" wizard
  * Step 1: enter "log4sdc-*" name for index pattern
  * Step 2: Use "time" field for Time Filter field name



