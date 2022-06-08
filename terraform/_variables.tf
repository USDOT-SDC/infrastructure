locals {
  // Setup some local vars to hold static and dynamic data
  common = {
    region_name      = "us-east-1"
    account_id  = nonsensitive(data.aws_ssm_parameter.account_id.value)
    region      = nonsensitive(data.aws_ssm_parameter.region.value)
    environment = nonsensitive(data.aws_ssm_parameter.environment.value)
    network = {
      vpc                       = data.aws_vpc.default
      subnet_ids                = data.aws_subnet_ids.default.ids
      default_security_group_id = data.aws_security_group.default.id
    }
    support_email    = nonsensitive(data.aws_ssm_parameter.support_email.value)
    terraform_bucket = "${data.aws_ssm_parameter.environment.value}.sdc.dot.gov.platform.terraform"
  }
  default_tags = {
    repository_url = "https://github.com/USDOT-SDC/"
    repository     = "infrastructure"
  }
  provider-profile = "sdc"
}
