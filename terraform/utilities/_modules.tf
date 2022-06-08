module "cleanup_worker" {
  source = "./cleanup-worker"
  common = var.common
}

module "dashboard" {
  source = "./dashboard"
  common = var.common
}

module "idle_resource_cleanup" {
  source = "./idle-resource-cleanup"
  common = var.common
}

module "instance_info" {
  source = "./instance-info"
  common = var.common
}

module "log4sdc" {
  source = "./log4sdc"
  common = var.common
}

