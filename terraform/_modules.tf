module "api" {
  module_name = "API"
  module_slug = "api"
  source      = "./api"
  common      = local.common
  route53_zones = {
    public  = aws_route53_zone.public
    private = aws_route53_zone.private
  }
  pub_fqdn     = local.pub_fqdn
  certificates = local.certificates
}

module "auto_start" {
  source = "./auto_start"
  common = local.common
}

# module "gitlab" {
#   module_name = "GitLab"
#   module_slug = "gitlab"
#   source      = "./gitlab"
#   common      = local.common
#   route53_zones = {
#     public  = aws_route53_zone.public
#     private = aws_route53_zone.private
#   }
#   pri_fqdn     = local.pri_fqdn
#   certificates = local.certificates
#   default_tags = local.default_tags
# }

module "instance-scheduler" {
  source = "./instance-scheduler"
  common = local.common
}

module "utilities" {
  source                             = "./utilities"
  common                             = local.common
  research_teams_vpc_endpoint_lambda = local.research_teams_vpc_endpoint_lambda
}

module "log4sdc" {
  source       = "./utilities/log4sdc"
  common       = local.common
  default_tags = local.default_tags
}

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
