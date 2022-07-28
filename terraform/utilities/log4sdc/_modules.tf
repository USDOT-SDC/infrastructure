module "apig" {
  source = "./apig/terraform"
  common = var.common
  default_tags = local.log4sdc_tags
}

module "lambda-elasticsearch" {
  source = "./lambda-elasticsearch/terraform"
  common = var.common
  default_tags = local.log4sdc_tags
}

module "sns" {
  source = "./sns/terraform"
  common = var.common
  default_tags = local.log4sdc_tags
}


