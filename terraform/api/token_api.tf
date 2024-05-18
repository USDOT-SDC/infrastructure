# The token resource is used to refresh the session token for an IAM role.
# === Resource ===
# === Method Request  -> Integration Request  ===
# === Method Response <- Integration Response ===
resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "token"
}

# === Resource -> Method ===
# === Resource -> Method -> Request ===
resource "aws_api_gateway_method" "token" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.token.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
  request_parameters = {
    "method.request.querystring.username" = true
    "method.request.querystring.pin"      = true
  }
}

# === Resource -> Method -> Integration -> Request ===
resource "aws_api_gateway_integration" "token" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.token.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.token.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

# === Resource -> Method -> Integration -> Response ===
# resource "aws_api_gateway_integration_response" "token" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.token.id
#   http_method = aws_api_gateway_method.token.http_method
#   status_code = aws_api_gateway_method_response.token.status_code
# }

# === Resource -> Method -> Response ===
# resource "aws_api_gateway_method_response" "token" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.token.id
#   http_method = aws_api_gateway_method.token.http_method
#   status_code = "200"
#   response_models = {
#     "application/json" = "Empty"
#   }
# }
