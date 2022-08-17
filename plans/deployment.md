# Version 0.3.0 Deployment Plan

### Deployment Build Environment
- Windows
- Install or update as needed
   - AWS CLI [version 2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
   - Terraform [1.2.7](https://releases.hashicorp.com/terraform/1.2.7/)
      - Updated from 1.2.2
   - hashicorp/aws [4.26.0](https://registry.terraform.io/providers/hashicorp/aws/4.26.0)
      - Updated from 4.17.1
   - hashicorp/archive [2.2.0](https://registry.terraform.io/providers/hashicorp/archive/2.2.0)
      - Updated from None
   - hashicorp/local [2.2.3](https://registry.terraform.io/providers/hashicorp/local/2.2.3)
      - Updated from None
   - hashicorp/null [3.1.1](https://registry.terraform.io/providers/hashicorp/null/3.1.1)
      - Updated from None

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
   1. Run `terraform plan -out=tfplan_v{version}`
      1. Check the plan, continue if it is correct
      1. Ensure there are no changes to out of scope resources
   1. Run `terraform apply tfplan_v{version}`
      1. This command uses the plan file specified  
         (it will not ask if you want to proceed)
      1. If needed, run `terraform show tfplan_v{version}` to check the plan
   1. Attach `tfplan_v{version}` to the Pull Request as a comment
   1. Execute the Test Plan to ensure the deployment was successful

### Individual module deployment
#### Utilities.Log4SDC Module
See https://github.com/USDOT-SDC/infrastructure/blob/main/plans/deployment.md

