data "archive_file" "token_lambda_deployment_package" {
  type        = "zip"
  source_file = "${path.module}/token/src/lambda_function.py"
  output_path = "${path.module}/token/deploy/lambda_deployment_package.zip"
}

resource "aws_lambda_function" "token" {
  function_name    = local.api_token_name
  description      = "Function to refresh an IAM role's sesstion token via API resource"
  filename         = data.archive_file.token_lambda_deployment_package.output_path
  source_code_hash = data.archive_file.token_lambda_deployment_package.output_base64sha256
  role             = aws_iam_role.token.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 6
  depends_on       = [data.archive_file.token_lambda_deployment_package]
  tags             = local.common_tags
}

resource "aws_lambda_permission" "token" {
  function_name = aws_lambda_function.token.function_name
  statement_id  = "allow_api_gateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}
