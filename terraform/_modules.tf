module "instance-scheduler" {
  source = "./instance-scheduler"
  common = local.common
}

module "gitlab" {
  source = "./gitlab"
  common = local.common
}

module "utilities" {
  source = "./utilities"
  common = local.common
}

module "web_portal" {
  source = "./web-portal"
  common = local.common
}
