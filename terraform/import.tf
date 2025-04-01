# import {
#   to = module.api.
#   id = ""
# }

# import {
#   to = aws_route53_zone.public
#   id = "Z103672221FNFH7O9E9OG"
# }

# import {
#   to = aws_route53_record.public_ns
#   id = "Z103672221FNFH7O9E9OG_sdc-dev.dot.gov_NS"
# }

# import {
#   to = aws_route53_record.public_soa
#   id = "Z103672221FNFH7O9E9OG_sdc-dev.dot.gov_SOA"
# }

# import {
#   to = aws_route53_zone.private
#   id = "Z04931192K8IHLCR9QGHU"
# }

# import {
#   to = aws_route53_record.private_ns
#   id = "Z04931192K8IHLCR9QGHU_dev.sdc.dot.gov_NS"
# }

# import {
#   to = aws_route53_record.private_soa
#   id = "Z04931192K8IHLCR9QGHU_dev.sdc.dot.gov_SOA"
# }

# import {
#   to = module.gitlab.aws_route53_record.gitlab
#   id = "Z04931192K8IHLCR9QGHU_gitlab.dev.sdc.dot.gov_A"
# }

# import {
#   to = aws_acm_certificate.external
#   id = "arn:aws:acm:us-east-1:505135622787:certificate/0dadb63d-8898-4260-ac16-545a2f0c4999"
# }

# uncomment for deployment
# import {
#   to = aws_s3_bucket.secrets
#   id = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.secrets"
# }

# import {
#   to = aws_s3_bucket_server_side_encryption_configuration.secrets
#   id = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.secrets"
# }

# import {
#   to = aws_s3_bucket_versioning.secrets
#   id = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.secrets"
# }

import {
  to = module.auto_start.aws_cloudwatch_log_group.this
  id = "/aws/lambda/instance_auto_start"
}
