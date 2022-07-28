data "aws_ssm_parameter" "elasticsearch_url" {
  name = "/log4sdc/elasticsearch_url"
}

data "aws_ssm_parameter" "lambda_binary_bucket" {
  name = "/common/secrets/lambda_binary_bucket"
}

data "aws_ssm_parameter" "requests_aws4auth" {
  name = "/log4sdc/requests_aws4auth"
}

