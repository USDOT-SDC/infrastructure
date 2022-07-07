variable "common" {}

locals {
  module = basename(abspath(path.module))
  edge_db_internal_server = data.aws_ssm_parameter.edge_db_internal_server.value
  edge_db_internal_port = data.aws_ssm_parameter.edge_db_internal_port.value
  edge_db_internal_user = data.aws_ssm_parameter.edge_db_internal_user.value
  edge_db_internal_password = data.aws_ssm_parameter.edge_db_internal_password.value
  edge_db_edge_server = data.aws_ssm_parameter.edge_db_edge_server.value
  edge_db_edge_port = data.aws_ssm_parameter.edge_db_edge_port.value
  edge_db_edge_user = data.aws_ssm_parameter.edge_db_edge_user.value
  edge_db_edge_password = data.aws_ssm_parameter.edge_db_edge_password.value
  tags = {
    "Project" = "SDC-Platform"
    "Team"    = "SDC-Platform"
    "Owner"   = "SDC Support Team"
    "Module"  = local.module
  }
}