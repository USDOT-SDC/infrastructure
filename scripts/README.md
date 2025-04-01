# Deployment Scripts

## Environment Setup
1. Follow instructions in the repo's [Environment Setup](/plans/setup.md)

## Tool Stack Versions
1. Run: `terraform --version`  
  Result should be:
    ```
    Terraform v1.11.x
    on windows_amd64
    ```
1. Run: `python --version`  
  Result should be:
    ```
    Python 3.13.x
    ```

## 1 tfinit
The `1-tfinit.cmd` script sets the active AWS profile (`set AWS_PROFILE=%env%`) and initializes Terraform (`terraform init`).  
### Parameters
The first parameter is the environment (dev | prod) to deploy to  
The second optional parameter sets an alternate AWS profile (e.g., default)  
### Examples
```
1-tfinit dev  
1-tfinit prod  
1-tfinit dev default
```
### Output
```
Your active AWS profile is: dev

terraform init -backend-config "bucket=dev.sdc.dot.gov.platform.terraform" -upgrade -reconfigure

Would you like to execute the above command to initialize Terraform?
Press Y for Yes, or C to Cancel.
```

## 2 tfplan
Terraform must be initialized (`1-tfinit {env}`) before running `2-tfplan`
### Example
```
2-tfplan  
```
### Output
```
Your active AWS profile is: dev

terraform plan -var=config_version="0.0.1" -var-file="env_vars/dev.tfvars" -out="tfplans/0.0.1_dev_147"

Would you like to execute the above command to create a Terraform execution plan?
Press Y for Yes, or C to Cancel.
```

## 3 tfapply
You must run `2-tfplan` to create a Terraform execution plan before running `3-tfapply`
### Example
```
3-tfapply  
```
### Output
```
Your active AWS profile is: dev

terraform apply "tfplans/0.0.1_dev_147"

Would you like to execute the above command to apply a Terraform execution plan?
Press Y for Yes, or C to Cancel.
```
