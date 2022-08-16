locals {
  // Setup some local vars to hold static and dynamic data
  common = {
    account_id  = nonsensitive(data.aws_ssm_parameter.account_id.value)
    region      = nonsensitive(data.aws_ssm_parameter.region.value)
    environment = nonsensitive(data.aws_ssm_parameter.environment.value)
    network = {
      vpc                    = data.aws_vpc.public
      subnets                = data.aws_subnets.public
      default_security_group = data.aws_security_group.default
    }
    support_email    = nonsensitive(data.aws_ssm_parameter.support_email.value)
    admin_email      = nonsensitive(data.aws_ssm_parameter.admin_email.value)
    terraform_bucket = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.terraform"
    backup_bucket    = aws_s3_bucket.backup
  }
  default_tags = {
    repository_url = "https://github.com/USDOT-SDC/"
    repository     = "infrastructure"
  }
  provider-profile = "sdc"
}
