module "apig" {
  source = "./apig/terraform"
  common = var.common
}

module "lambda-elasticsearch" {
  source = "./lambda-elasticsearch/terraform"
  common = var.common
}

module "sns" {
  source = "./sns/terraform"
  common = var.common
}

