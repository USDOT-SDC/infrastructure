# Environment Setup
1. Install AWS CLI version 2 [download here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
1. Install Terraform `~> 1.0` [download here](https://releases.hashicorp.com/terraform/)
1. Configuration
   1. Update `terraform/configuration.tf` if needed
      1. terraform.backend.s3.region and key
      1. terraform.backend.s3.key
   1. Update `terraform/variables.tf`
1. Use the AWS Console to verify the AWS Systems Manager Parameter Store is set up
   1. Name = `environment`
   1. Description = `The environment of this AWS account (dev, test, stage or prod)`
   1. Tier = `Standard`
   1. Type = `String`
   1. Data type = `text`
   1. Value = As appropriate: `dev`, `test`, `stage` or `prod`
1. Use the AWS Console to verify the Terraform backend bucket is set up
   1. Name = `{env}.sdc.dot.gov.platform.terraform`
   1. Bucket Versioning = `Enabled`
   1. Default encryption = `Enabled`
