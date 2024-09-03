# use caution when making changes to outputs
# these are put into the tfstate file and used by other Terraform configurations
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

output "route53_zone" {
  value = {
    public = {
      id  = aws_route53_zone.public.id
      arn = aws_route53_zone.public.arn
    }
    private = {
      id  = aws_route53_zone.private.id
      arn = aws_route53_zone.private.arn
    }
  }
}

output "certificates" {
  value = {
    external = {
      arn         = aws_acm_certificate.external.arn
      domain_name = aws_acm_certificate.external.domain_name
    }
    internal = {
      arn         = aws_acm_certificate.internal.arn
      domain_name = aws_acm_certificate.internal.domain_name
    }
  }
}
