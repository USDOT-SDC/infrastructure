module "api_gateway" {
  source = "./api-gateway"
  common = var.common
}

module "guacamole" {
  source = "./guacamole"
  common = var.common
}

module "lambdas" {
  source = "./lambdas"
  common = var.common
}

module "nginx" {
  source = "./nginx"
  common = var.common
}

module "web_app" {
  source = "./web-app"
  common = var.common
}

output "webportal_api" {
  value = module.api-gateway.webportal_api
}

output "webportal_authorizer" {
  value = module.api-gateway.webportal_authorizer
}