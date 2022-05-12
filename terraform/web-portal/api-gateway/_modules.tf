module "login_gov" {
  source = "./login-gov"
  common = local.common
}

module "web_portal" {
  source = "./web-portal"
  common = local.common
}
