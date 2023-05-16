locals {
  // Setup some local vars to hold static and dynamic data
  # use caution when making changes to local.common
  # local.common is output to tfstate and used by other configurations
  common = {
    account_id  = nonsensitive(data.aws_ssm_parameter.account_id.value)
    region      = nonsensitive(data.aws_ssm_parameter.region.value)
    environment = nonsensitive(data.aws_ssm_parameter.environment.value)
    network = {
      vpc = data.aws_vpc.default
      subnets = concat(
        [module.vpc.subnet_support.id],
        [module.vpc.subnet_researcher.id],
        tolist(module.vpc.subnets_infrastructure[*].id),
      )
      subnet_support         = module.vpc.subnet_support
      subnet_researcher      = module.vpc.subnet_researcher
      subnet_three           = module.vpc.subnets_infrastructure[0]
      subnet_four            = module.vpc.subnets_infrastructure[1]
      subnet_five            = module.vpc.subnets_infrastructure[2]
      subnet_six             = module.vpc.subnets_infrastructure[3]
      default_security_group = data.aws_security_group.default
      transit_gateway        = data.aws_ec2_transit_gateway.default
    }
    support_email               = nonsensitive(data.aws_ssm_parameter.support_email.value)
    admin_email                 = nonsensitive(data.aws_ssm_parameter.admin_email.value)
    terraform_bucket            = aws_s3_bucket.terraform
    backup_bucket               = aws_s3_bucket.backup
    instance_maintenance_bucket = aws_s3_bucket.instance_maintenance
  }
  default_tags = {
    "Repository URL" = "https://github.com/USDOT-SDC/"
    Repository       = "infrastructure"
    Project          = "SDC-Platform"
    Team             = "SDC-Platform"
    Owner            = "SDC Support Team"
  }
  provider-profile = "sdc"
}
