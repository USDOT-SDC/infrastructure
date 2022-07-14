#NOTE: This file contains the init of the Web-Portal API and it's foundational stages, resources, and methods. Additional changes have been made to this resource in the EdgeDB module. 

data "aws_api_gateway_rest_api" "webportal" { 
  name = "ecs-${var.common.enviornment}-webportal"
}

data "aws_cognito_user_pools" "webportal_cognito" {
  name = "${var.common.enviornment}-sdc-dot-cognito-pool"
}


data "aws_api_gateway_authorizer" "webportal" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = data.aws_api_gateway_rest_api.webportal.id
  provider_arns = data.aws_cognito_user_pools.webportal_cognito.arns
}


output "webportal_api" {
  value = data.aws_api_gateway_rest_api.webportal
}

output "webportal_authorizer" {
  value = data.aws_api_gateway_authorizer.webportal
}

############################# ADD Cognito UserPool Resource If It Isn't Already Defined ################

# resource "aws_api_gateway_rest_api" "webportal" { 
#   name = "ecs-${var.common.enviornment}-webportal"
# }

# resource "aws_api_gateway_resource" "webportal" {
#   rest_api_id = aws_api_gateway_rest_api.webportal.id
#   parent_id   = aws_api_gateway_rest_api.webportal.root_resource_id
#   path_part   = "/"
# }

# resource "aws_api_gateway_authorizer" "webportal" {
#   name          = "CognitoUserPoolAuthorizer"
#   type          = "COGNITO_USER_POOLS"
#   rest_api_id   = aws_api_gateway_rest_api.webportal.id
#   provider_arns = var.common.webportal_cognito.arns
# }

# resource "aws_lambda_permission" "apigw_lambda" { #Do we need this for lambda role or is this already defined?
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = local.webportal_lambda
#   principal     = "apigateway.amazonaws.com"
# }