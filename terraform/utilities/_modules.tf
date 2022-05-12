module "cleanup_worker" {
  source = "./cleanup-worker"
  common = local.common
}

module "dashboard" {
  source = "./dashboard"
  common = local.common
}

module "idle_resource_cleanup" {
  source = "./idle-resource-cleanup"
  common = local.common
}

module "instance_info" {
  source = "./instance-info"
  common = local.common
}

module "log4sdc" {
  source = "./log4sdc"
  common = local.common
}

