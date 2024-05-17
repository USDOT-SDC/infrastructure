data "archive_file" "token_lambda_deployment_package" {
  type        = "zip"
  source_file = "${path.module}/token/src/lambda_function.py"
  output_path = "${path.module}/token/deploy/lambda_deployment_package.zip"
}

resource "aws_lambda_function" "token" {
  function_name    = "api_token"
  description      = "Function to refresh an IAM role's sesstion token via API resource"
  filename         = data.archive_file.token_lambda_deployment_package.output_path
  source_code_hash = data.archive_file.token_lambda_deployment_package.output_base64sha256
  role             = "arn:aws:iam::505135622787:role/service-role/api_generate_token"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 6
  depends_on       = [data.archive_file.token_lambda_deployment_package]
  tags             = local.common_tags
}
