# use caution when making changes to local.common
# local.common is output to tfstate and used by other configurations
output "common" {
    value = local.common
}
