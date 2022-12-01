variable "common" {}

locals {
  subnet_firewall    = jsondecode(file("../../infrastructure-secrets/vpc/dev-subnet-firewall.json"))
  subnets_routing    = jsondecode(file("../../infrastructure-secrets/vpc/dev-subnets-routing.json"))
  subnet_researcher = jsondecode(file("../../infrastructure-secrets/vpc/dev-subnet-researcher.json"))
}
