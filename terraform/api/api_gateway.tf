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
