# Rollback Plan

[v1.2](https://github.com/USDOT-SDC/log4sdc/tree/1.2)

* Log on into the AWS Console for the SDC system account, navigate to the gitlab autoscaling group launch template configuration
* Delete the latest template version so that the previous stable version becomes the latest
* In the autoscaling group instance management view, initiate instance refresh.

## Rollback of [v1.2](https://github.com/USDOT-SDC/log4sdc/tree/1.2)

* Clone the log4sdc repository into a Linux environment (e.g., SDC build machine)
* Change to the log4sdc folder

### SNS Topic rollback
* Change to the sns/terraform folder
  * cd sns/terraform
* Execute the following commands to perform the reollback:
  * terraform init -var-file=config/backend-ecs-prod.tfvars
  * terraform destroy -var-file=config/ecs-prod.tfvars

### ElasticSearch publisher lambda function deployment
* Change to the lambda-elasticsearch/terraform folder
  * cd lambda-elasticsearch/terraform
* Execute the following commands to perform the rollback:
  * terraform init -var-file=config/backend-ecs-prod.tfvars
  * terraform destroy -var-file=config/ecs-prod.tfvars

### ElasticSearch index and index pattern deployment
* Log on into AWS console
* Navigate to OpenSearch Kibana interface
* Follow ElasticSearch documentation to delete log4sdc index and index pattern.


