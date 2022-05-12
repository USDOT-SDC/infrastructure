terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    // Variables can not be used here
    region = "us-east-1"
    key = "infrastructure/terraform/terraform.tfstate"
  }
}

provider "aws" {
  region = local.region
  profile = "sdc"
  default_tags {
    tags = local.default_tags
  }
}
