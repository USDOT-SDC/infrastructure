#module "log4sdcElasticSearchPublisher" {
#  source                        = "./log4sdc-elasticsearch-publisher"
#  lambda_name                   = "log4sdc-elasticsearch-publisher"
#  lambda_handler                = "log4sdc-elasticsearch-publisher.lambda_handler"
#  environment                   = "${data.aws_ssm_parameter.environment.value}"
#  lambda_binary_bucket          = "${data.aws_ssm_parameter.lambda_binary_bucket.value}"
#  account_number                = "${data.aws_ssm_parameter.account_number.value}"
#  aws_region                    = local.aws_region
#  tags                          = local.global_tags
#}

data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "utilities/log4sdc/lambda-elasticsearch/src"
    output_path = "utilities/log4sdc/lambda-elasticsearch/log4sdc-es-publisher.zip"
}

resource "aws_lambda_function" "log4sdc_es_publisher" {
    filename = "utilities/log4sdc/lambda-elasticsearch/log4sdc-es-publisher.zip"
    function_name = "log4sdc-elasticsearch-publisher"
    role = aws_iam_role.log4sdc_es_publisher_role.arn
    handler = "lambda-elasticsearch-publisher.lambda_handler"
    timeout = 30
    runtime = "python3.8"
    layers = ["arn:aws:lambda:us-east-1:${local.account_number}:layer:${local.requests_aws4auth}"]
    environment {
      variables = {
        LOG_LEVEL = local.log_level
        ELASTICSEARCH_URL = local.elasticsearch_url 
        AWS_ACCOUNT_NUM = local.account_number
      }
    }
    tags = local.global_tags
}

resource "aws_iam_role" "log4sdc_es_publisher_role" {
    name = "log4sdc-elasticsearch-publisher-role"
    assume_role_policy = file("utilities/log4sdc/lambda-elasticsearch/terraform/assume_role_policy.json")
    tags = local.global_tags
}

resource "aws_iam_role_policy" "log4sdc_es_publisher_policy" {
    name="log4sdc-elasticsearch-publisher-policy"
    role = aws_iam_role.log4sdc_es_publisher_role.id
    policy = file("utilities/log4sdc/lambda-elasticsearch/terraform/log4sdc_es_publisher_policy.json")
}


