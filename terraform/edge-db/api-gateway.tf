
# Appending EdgeDB features to original web-portal API from terrraform/web-portal/api-gateway/web-portal.tf
locals{
    webportal_lambda = "webportal-ecs-dev"
}

data "aws_lambda_function" "webportal" {
  function_name = local.webportal_lambda
}


resource "aws_api_gateway_rest_api_policy" "webportal" {
  rest_api_id = var.common.webportal_api.id
  policy = file("${local.module}/policies/api-gateway_policy.json")
  lifecycle {
    ignore_changes = [
      policy
    ]
  }
}

resource "aws_api_gateway_resource" "exportTable" {
  rest_api_id = var.common.webportal_api.id
  parent_id   = var.common.webportal_api.root_resource_id
  path_part   = "exportTable"
  lifecycle {
    ignore_changes = [
      path_part
    ]
  }
}

resource "aws_api_gateway_method" "exportTable_OPTIONS" {
    rest_api_id   = var.common.webportal_api.id
    resource_id   = aws_api_gateway_resource.exportTable.id
    http_method   = "OPTIONS"
    authorization = "NONE"
    lifecycle {
    ignore_changes = [
      http_method
    ]
  }
}

resource "aws_api_gateway_method_response" "options_method_response_200" {
    rest_api_id   = var.common.webportal_api.id
    resource_id   = aws_api_gateway_resource.exportTable.id
    http_method   = aws_api_gateway_method.exportTable_OPTIONS.http_method
    status_code   = "200"
    response_models {
      "application/json" = "Empty"
    }
    response_parameters {
        "method.response.header.Access-Control-Allow-Credentials" = true
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true,
        "method.response.header.Access-Control-Expose-Headers" = true,
        "method.response.header.Access-Control-Max-Age" = true
    }
    lifecycle {
    ignore_changes = [
      response_parameters
    ]
    }
  # depends_on = [aws_api_gateway_method.exportTable_OPTIONS]
}

resource "aws_api_gateway_integration" "options_integration_request" {
    rest_api_id   = var.common.webportal_api.id
    resource_id   = aws_api_gateway_resource.exportTable.id
    http_method   = aws_api_gateway_method.exportTable_OPTIONS.http_method
    type          = "MOCK"
  lifecycle {
    ignore_changes = [
      type
    ]
  }
    # depends_on = [aws_api_gateway_method.exportTable_OPTIONS]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = var.common.webportal_api.id
    resource_id   = aws_api_gateway_resource.exportTable.id
    http_method   = aws_api_gateway_method.exportTable_OPTIONS.http_method
    status_code   = aws_api_gateway_method_response.options_method_response_200.status_code
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Access-Control-Allow-Origin'",
        "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'",
        "method.response.header.Access-Control-Allow-Credentials" = "'true'",
        "method.response.header.Access-Control-Expose-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Access-Control-Allow-Origin'",
        "method.response.header.Access-Control-Max-Age" = "'600'",
    }
  lifecycle {
    ignore_changes = [
      response_parameters
    ]
  }
    # depends_on = [aws_api_gateway_method_response.options_200]
}

resource "aws_api_gateway_method" "exportTable_POST" {
  rest_api_id   = var.common.webportal_api.id
  resource_id   = aws_api_gateway_resource.exportTable.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = var.common.webportal_authorizer.id
  request_parameters = {
    "method.request.path.proxy" = true
  }
  lifecycle {
    ignore_changes = [
      request_parameters
    ]
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = var.common.webportal_api.id
  resource_id             = aws_api_gateway_resource.exportTable.id
  http_method             = aws_api_gateway_method.exportTable_POST.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webportal.invoke_arn
  lifecycle {
    ignore_changes = [
      integration_http_method
    ]
  }
}

