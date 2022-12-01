variable "common" {}

locals {
  subnet_firewall        = jsondecode(file("../../infrastructure-secrets/vpc/${var.common.environment}-subnet-firewall.json"))
  subnets_routing        = jsondecode(file("../../infrastructure-secrets/vpc/${var.common.environment}-subnets-routing.json"))
  subnet_support         = jsondecode(file("../../infrastructure-secrets/vpc/${var.common.environment}-subnet-support.json"))
  subnet_researcher      = jsondecode(file("../../infrastructure-secrets/vpc/${var.common.environment}-subnet-researcher.json"))
  subnets_infrastructure = jsondecode(file("../../infrastructure-secrets/vpc/${var.common.environment}-subnets-infrastructure.json"))
}
