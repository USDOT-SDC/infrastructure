module "api_gateway" {
  source = "./api-gateway"
  common = local.common
}

module "guacamole" {
  source = "./guacamole"
  common = local.common
}

module "lambdas" {
  source = "./lambdas"
  common = local.common
}

module "nginx" {
  source = "./nginx"
  common = local.common
}

module "web_app" {
  source = "./web-app"
  common = local.common
}
