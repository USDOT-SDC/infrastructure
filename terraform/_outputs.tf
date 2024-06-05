# use caution when making changes to local.common
# local.common is output to tfstate and used by other configurations
# the common output is deprecated. use vpc or s3 outputs, or read directly from the ssm parameters
output "common" {
  value = {
    account_id  = nonsensitive(data.aws_ssm_parameter.account_id.value)
    region      = nonsensitive(data.aws_ssm_parameter.region.value)
    environment = nonsensitive(data.aws_ssm_parameter.environment.value)
    network = {
      vpc = { id = data.aws_vpc.default.id }
      subnets = concat(
        [module.vpc.subnet_support.id],
        [module.vpc.subnet_researcher.id],
        tolist(module.vpc.subnets_infrastructure[*].id),
      )
      subnet_support         = { id = module.vpc.subnet_support.id }
      subnet_researcher      = { id = module.vpc.subnet_researcher.id }
      subnet_three           = { id = module.vpc.subnets_infrastructure[0].id }
      subnet_four            = { id = module.vpc.subnets_infrastructure[1].id }
      subnet_five            = { id = module.vpc.subnets_infrastructure[2].id }
      subnet_six             = { id = module.vpc.subnets_infrastructure[3].id }
      default_security_group = { id = data.aws_security_group.default.id }
      transit_gateway        = { id = data.aws_ec2_transit_gateway.default.id }
    }
    support_email               = nonsensitive(data.aws_ssm_parameter.support_email.value)
    admin_email                 = nonsensitive(data.aws_ssm_parameter.admin_email.value)
    terraform_bucket            = { id = aws_s3_bucket.terraform.id }
    backup_bucket               = { id = aws_s3_bucket.backup.id }
    instance_maintenance_bucket = { id = aws_s3_bucket.instance_maintenance.id }
  }
}

output "vpc" {
  value = {
    id = data.aws_vpc.default.id
    subnets = concat(
      [module.vpc.subnet_support.id],
      [module.vpc.subnet_researcher.id],
      tolist(module.vpc.subnets_infrastructure[*].id),
    )
    subnet_support         = { id = module.vpc.subnet_support.id }
    subnet_researcher      = { id = module.vpc.subnet_researcher.id }
    subnet_three           = { id = module.vpc.subnets_infrastructure[0].id }
    subnet_four            = { id = module.vpc.subnets_infrastructure[1].id }
    subnet_five            = { id = module.vpc.subnets_infrastructure[2].id }
    subnet_six             = { id = module.vpc.subnets_infrastructure[3].id }
    default_security_group = { id = data.aws_security_group.default.id }
    transit_gateway        = { id = data.aws_ec2_transit_gateway.default.id }
  }
}

output "s3" {
  value = {
    terraform            = { bucket = aws_s3_bucket.terraform.bucket }
    backup               = { bucket = aws_s3_bucket.backup.bucket }
    instance_maintenance = { bucket = aws_s3_bucket.instance_maintenance.bucket }
  }
}

output "disk_alert_linux_script" {
  value = module.utilities.disk_alert_linux_script
}

output "auto_start" {
  value = {
    dynamodb_tables = module.auto_start.dynamodb_tables
  }
}
