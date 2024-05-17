data "aws_caller_identity" "current" {}

data "terraform_remote_state" "research_teams" {
  backend = "s3"
  config = {
    region = "us-east-1"
    bucket = aws_s3_bucket.terraform.id
    key    = "research-teams/terraform/terraform.tfstate"
  }
}

data "terraform_remote_state" "portal2" {
  backend = "s3"
  config = {
    region = "us-east-1"
    bucket = aws_s3_bucket.terraform.id
    key    = "portal2/terraform/terraform.tfstate"
  }
}
