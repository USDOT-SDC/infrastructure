locals {
  // Setup some local vars to hold static and dynamic data
  common = {
    account_id  = nonsensitive(data.aws_ssm_parameter.account_id.value)
    region      = nonsensitive(data.aws_ssm_parameter.region.value)
    environment = nonsensitive(data.aws_ssm_parameter.environment.value)
    network = {
      vpc                       = data.aws_vpc.public
      subnet_ids                = data.aws_subnet_ids.public.ids
      default_security_group_id = data.aws_security_group.default.id
    }
    support_email = nonsensitive(data.aws_ssm_parameter.support_email.value)
  }
  default_tags = {
    repository_url = "https://github.com/USDOT-SDC/"
    repository     = "infrastructure"
  }
}
