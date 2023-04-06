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

### Log4sdc SNS Topic module deployment
* Change to the infrastructure/terraform folder
  * cd infrastructure/terraform
* Execute the following command to deploy the updates:
  * utilities/log4sdc/sns/reapply.sh

### Log4sdc lambda layer deployment
* Change to the infrastructure/log4sdc/lambda-layer/deploy folder
  * cd infrastructure/log4sdc/lambda-layer/deploy
* Execute the following command to deploy the lambda layer:
  * ./deploy-common-layer.sh

### ElasticSearch publisher lambda function deployment
* Change to the infrastructure/terraform folder
  * cd infrastructure/terraform
* Execute the following command to deploy the updates:
  * utilities/log4sdc/lambda-elasticsearch/reapply.sh
 
### Log4sdc specific team deployment
* Set up the following SSM parameter to include desired teams:
 ```
 /log4sdc/teams
 ```
 
 Use json format for definition. Here is an example for an "acme" team. Multiple teams are accepted. Make team identifier short: it will be used as a prefix for SNS topic name.
 ```
 {
  "acme": {
    "emails": ["email_1@acme.com", "email_2@acme.com"],
    "sms_numbers": ["+18885551212"]
  }
 }
 ```

* Change to the infrastructure/terraform folder
  * cd infrastructure/terraform
* Execute the following command to deploy the updates:
  * utilities/log4sdc/sns/reapply.sh


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


