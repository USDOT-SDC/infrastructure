module "login_gov" {
  source = "./login-gov"
  common = var.common
}

module "web_portal" {
  source = "./web-portal"
  common = var.common
}
