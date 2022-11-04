locals {
  // Setup some local vars to hold static and dynamic data
  common = {
    account_id  = nonsensitive(data.aws_ssm_parameter.account_id.value)
    region      = nonsensitive(data.aws_ssm_parameter.region.value)
    environment = nonsensitive(data.aws_ssm_parameter.environment.value)
    network = {
      vpc = data.aws_vpc.public
      subnets = [
        data.aws_subnet.support.id,
        data.aws_subnet.researcher.id,
        data.aws_subnet.three.id,
        data.aws_subnet.four.id,
        data.aws_subnet.five.id,
        data.aws_subnet.six.id,
      ]
      subnet_support         = data.aws_subnet.support
      subnet_researcher      = data.aws_subnet.researcher
      subnet_three           = data.aws_subnet.three
      subnet_four            = data.aws_subnet.four
      subnet_five            = data.aws_subnet.five
      subnet_six             = data.aws_subnet.six
      default_security_group = data.aws_security_group.default
    }
    support_email    = nonsensitive(data.aws_ssm_parameter.support_email.value)
    admin_email      = nonsensitive(data.aws_ssm_parameter.admin_email.value)
    terraform_bucket = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.terraform"
    backup_bucket    = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.backup"
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
