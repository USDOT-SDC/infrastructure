# === REST API ===
resource "aws_api_gateway_rest_api" "api" {
  name        = "api"
  description = "SDC API"
  tags        = local.common_tags
}

# === REST API Domain Name ===
data "aws_acm_certificate" "external" {
  domain   = local.fqdn
  statuses = ["ISSUED"]
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name     = "api.${local.fqdn}"
  certificate_arn = data.aws_acm_certificate.external.arn
}

# === REST API Domain Name Mapping ===
resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.v1.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
  base_path   = "v1"
}

# === REST API Stage ===
resource "aws_api_gateway_stage" "v1" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "v1"
  tags          = local.common_tags
}

# The health resource is an example of the Terraform resources
# necessary to build a complete API resource integration.
# === Resource ===
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "health"
}

# === Resource -> Method ===
# === Resource -> Method -> Request ===
resource "aws_api_gateway_method" "health_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "GET"
  authorization = "NONE"
}

# === Resource -> Method -> Integration -> Request ===
resource "aws_api_gateway_integration" "health_get_mock" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.health.id
  http_method          = aws_api_gateway_method.health_get.http_method
  type                 = "MOCK"
  timeout_milliseconds = 1000
  request_templates = {
    "application/json" = jsonencode(
      {
        "statusCode" : 200
      }
    )
  }
}

# === Resource -> Method -> Integration -> Response ===
resource "aws_api_gateway_integration_response" "health_get_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.health_get.http_method
  status_code = aws_api_gateway_method_response.health_get_200.status_code

  response_templates = {
    "application/json" = jsonencode(
      {
        "isHealthy" : true,
        "source" : "sdc-api"
      }
    )
  }
}

# === Resource -> Method -> Response ===
resource "aws_api_gateway_method_response" "health_get_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.health_get.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

# === REST API Deployment ===
# To properly capture all REST API configuration in a deployment, 
# this resource must have triggers on all prior Terraform resources 
# that manage resources/paths, methods, integrations, etc.
resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(
      jsonencode(
        [
          aws_api_gateway_resource.health,
          aws_api_gateway_method.health_get,
          aws_api_gateway_integration.health_get_mock,
          aws_api_gateway_integration_response.health_get_200,
          aws_api_gateway_method_response.health_get_200,
        #   module.api
        ]
      )
    )
  }
  lifecycle {
    create_before_destroy = true
  }
}
