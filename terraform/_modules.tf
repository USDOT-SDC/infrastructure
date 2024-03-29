module "vpc" {
  source = "./vpc"
  common = {
    account_id  = nonsensitive(data.aws_ssm_parameter.account_id.value)
    region      = nonsensitive(data.aws_ssm_parameter.region.value)
    environment = nonsensitive(data.aws_ssm_parameter.environment.value)
    network = {
      vpc                    = data.aws_vpc.default
      default_security_group = data.aws_security_group.default
      transit_gateway        = data.aws_ec2_transit_gateway.default
    }
    support_email    = nonsensitive(data.aws_ssm_parameter.support_email.value)
    admin_email      = nonsensitive(data.aws_ssm_parameter.admin_email.value)
    terraform_bucket = aws_s3_bucket.terraform.id
    backup_bucket    = aws_s3_bucket.backup.id
  }
}

module "instance-scheduler" {
  source = "./instance-scheduler"
  common = local.common
}

module "log4sdc" {
  source       = "./utilities/log4sdc"
  common       = local.common
  default_tags = local.default_tags
}

module "utilities" {
  source = "./utilities"
  common = local.common
}
