variable "common" {}

locals {
  lambda_src_path = "${path.module}/src"
  tags = {
    module = "auto-start"
  }
}
