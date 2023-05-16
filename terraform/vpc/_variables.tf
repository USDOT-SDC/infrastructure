variable "common" {}

locals {
  subnets = yamldecode(file("../../infrastructure-secrets/vpc/${var.common.environment}-subnets.yaml"))
}
