# use caution when making changes to local.common
# local.common is output to tfstate and used by other configurations
output "common" {
  value = local.common
}
output "disk_alert_linux_script" {
  value = module.utilities.disk_alert_linux_script
}
