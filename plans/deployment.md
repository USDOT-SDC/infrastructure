# Version 0.4.4 Deployment Plan

### Deployment Build Environment
- Windows
- Install or update as needed
   - AWS CLI [version 2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
   - Terraform 1.4.6
      - *Updated from 1.3.4*
   - hashicorp/aws 4.67.1
      - *Updated from 4.66.0*
   - hashicorp/archive 2.3.0
      - *Updated from 2.2.0*
   - hashicorp/local 2.4.0
      - *Updated from 2.2.3*
   - hashicorp/null 3.2.1
      - *Updated from 3.2.0*

### Deployment
Notes:
- Curly brackets denote variables that must be replaced with actual values.
- This deployment relies on values set in the AWS Systems Manager Parameter Store.
- This deployment relies on a Terraform backend bucket that is set up outside of this repo.

1. Pull this version's tag from the repo
1. Use Terraform to deploy the infrastructure-as-code
   1. Navigate to the root module directory `terraform`
   1. Run `terraform init -backend-config "bucket={environment}.{domain}.platform.terraform"`
   1. Run `terraform init -version` to verify the installed Terraform and AWS Provider versions, update as needed
   1. Run `terraform import aws_s3_bucket.terraform {environment}.{domain}.platform.terraform`
   1. Run `terraform plan -out=tfplan_v{version}`
      1. Check the plan, continue if it is correct
      1. Ensure there are no changes to out of scope resources
   1. Run `terraform apply tfplan_v{version}`
      1. This command uses the plan file specified  
         (it will not ask if you want to proceed)
      1. If needed, run `terraform show tfplan_v{version}` to check the plan
   1. Attach `tfplan_v{version}` to the Pull Request as a comment
   1. Execute the Test Plan to ensure the deployment was successful
