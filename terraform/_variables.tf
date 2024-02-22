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
    support_email                      = nonsensitive(data.aws_ssm_parameter.support_email.value)
    admin_email                        = nonsensitive(data.aws_ssm_parameter.admin_email.value)
    terraform_bucket                   = { id = aws_s3_bucket.terraform.id }
    backup_bucket                      = { id = aws_s3_bucket.backup.id }
    instance_maintenance_bucket        = { id = aws_s3_bucket.instance_maintenance.id }
    research_teams_vpc_endpoint_lambda = data.terraform_remote_state.research_teams.outputs.vpc_endpoint_lambda.dns_entry[0].dns_name
  }
  default_tags = {
    "Repository URL" = "https://github.com/USDOT-SDC/"
    Repository       = "infrastructure"
    Project          = "Platform"
    Team             = "Platform"
    Owner            = "Support Team"
  }
}
