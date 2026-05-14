variable "common" {}

locals {
  subnets = yamldecode(file("../../infrastructure-secrets/vpc/${var.common.environment}-subnets.yaml"))
  subnet_tags = {
    "Panorama-Mode"         = "OST"
    "Panorama-AWS-Acct"     = "ost-sdc-${var.common.environment}"
    "Panorama-Subnet-Usage" = "Custom"
    "Panorama-Zone"         = "Inside"
    "Panorama-AWS-AllowAll" = "Yes"
  }
}
