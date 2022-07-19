resource "aws_api_gateway_rest_api" "log4sdc-api" {
  name = "log4sdc-api"
  description = "log4sdc-api"
  tags = local.global_tags
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "GatewayDeployment" {
  rest_api_id = aws_api_gateway_rest_api.log4sdc-api.id
  variables = {
    timestamp = timestamp()
  }
  lifecycle {
    create_before_destroy = true
  }
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.HealthCheck.id,
      aws_api_gateway_method.HealthCheckGet.id,
      aws_api_gateway_integration.HealthCheckIntegration.id,
      aws_api_gateway_resource.Enqueue.id,
      aws_api_gateway_method.EnqueueMethod.id,
      aws_api_gateway_integration.EnqueueIntegration.id,
    ]))
  }
}

# Health
resource "aws_api_gateway_resource" "HealthCheck" {
  rest_api_id = aws_api_gateway_rest_api.log4sdc-api.id
  parent_id   = aws_api_gateway_rest_api.log4sdc-api.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_method" "HealthCheckGet" {
  rest_api_id   = aws_api_gateway_rest_api.log4sdc-api.id
  resource_id   = aws_api_gateway_resource.HealthCheck.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "HealthCheckIntegration" {
  rest_api_id          = aws_api_gateway_rest_api.log4sdc-api.id
  resource_id          = aws_api_gateway_resource.HealthCheck.id
  http_method          = aws_api_gateway_method.HealthCheckGet.http_method
  type                 = "MOCK"
  timeout_milliseconds = 1000

  request_templates = {
    "application/json" = <<-EOF
    {
      "statusCode": 200
    }
    EOF
  }
}

resource "aws_api_gateway_method_response" "HealthCheckMethodResponse" {
  rest_api_id = aws_api_gateway_rest_api.log4sdc-api.id
  resource_id = aws_api_gateway_resource.HealthCheck.id
  http_method = aws_api_gateway_method.HealthCheckGet.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "HealthCheckIntegrationResponse" {
  depends_on  = [aws_api_gateway_integration.HealthCheckIntegration]
  rest_api_id = aws_api_gateway_rest_api.log4sdc-api.id
  resource_id = aws_api_gateway_resource.HealthCheck.id
  http_method = aws_api_gateway_method.HealthCheckGet.http_method
  status_code = aws_api_gateway_method_response.HealthCheckMethodResponse.status_code

  response_templates = {
    "application/json" = <<-EOF
    {
      "isHealthy" : true,
      "source": "log4sdc-api"
    }
    EOF
  }
}

resource "aws_api_gateway_stage" "log4sdc-api-stage" {
  deployment_id = aws_api_gateway_deployment.GatewayDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.log4sdc-api.id
  stage_name    = "log4sdc-api"
}

# Enqueue
resource "aws_api_gateway_resource" "Enqueue" {
  rest_api_id = aws_api_gateway_rest_api.log4sdc-api.id
  parent_id   = aws_api_gateway_rest_api.log4sdc-api.root_resource_id
  path_part   = "enqueue"
}

resource "aws_api_gateway_method" "EnqueueMethod" {
  rest_api_id   = aws_api_gateway_rest_api.log4sdc-api.id
  resource_id   = aws_api_gateway_resource.Enqueue.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "EnqueueMethodResponse" {
  rest_api_id = aws_api_gateway_rest_api.log4sdc-api.id
  resource_id = aws_api_gateway_resource.Enqueue.id
  http_method = aws_api_gateway_method.EnqueueMethod.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "EnqueueIntegrationResponse" {
  depends_on  = [aws_api_gateway_integration.EnqueueIntegration]
  rest_api_id = aws_api_gateway_rest_api.log4sdc-api.id
  resource_id = aws_api_gateway_resource.Enqueue.id
  http_method = aws_api_gateway_method.EnqueueMethod.http_method
  status_code = aws_api_gateway_method_response.EnqueueMethodResponse.status_code

  response_templates = {
    "application/json" = <<-EOF
    {
      "enqueue" : true,
      "source": "log4sdc-api"
    }
    EOF
  }
}

resource "aws_api_gateway_integration" "EnqueueIntegration" {
  rest_api_id          = aws_api_gateway_rest_api.log4sdc-api.id
  resource_id          = aws_api_gateway_resource.Enqueue.id
  http_method             = "POST"
  type                    = "AWS"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"
  credentials             = aws_iam_role.api.arn
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${aws_sqs_queue.log4sdc_sqs.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

resource "aws_ssm_parameter" "log4sdc_api_id" {
  name  = "/log4sdc/API_ID"
  type  = "String"
  value = aws_api_gateway_rest_api.log4sdc-api.id  
}

