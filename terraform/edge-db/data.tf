data "aws_subnet" "researchers" {
  filter {
    name   = "tag:Name"
    values = ["Researcher Workstations/GitLab"]
  }
}

data "aws_subnet" "support" {
  filter {
    name   = "tag:Name"
    values = ["Hadoop/DW Loader/Support WS"]
  }
}

resource "aws_ssm_parameter" "edge_db_edge_server" {
  name  = "/${var.repository}/${local.module}/edge_db_edge/server"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_edge_server" {
  name       = "/${var.repository}/${local.module}/edge_db_edge/server"
  depends_on = [aws_ssm_parameter.edge_db_edge_server]
}

resource "aws_ssm_parameter" "edge_db_edge_port" {
  name  = "/${var.repository}/${local.module}/edge_db_edge/port"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_edge_port" {
  name       = "/${var.repository}/${local.module}/edge_db_edge/port"
  depends_on = [aws_ssm_parameter.edge_db_edge_port]
}

resource "aws_ssm_parameter" "edge_db_edge_user" {
  name  = "/${var.repository}/${local.module}/edge_db_edge/user"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_edge_user" {
  name       = "/${var.repository}/${local.module}/edge_db_edge/user"
  depends_on = [aws_ssm_parameter.edge_db_edge_user]
}

resource "aws_ssm_parameter" "edge_db_edge_password" {
  name  = "/${var.repository}/${local.module}/edge_db_edge/password"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_edge_password" {
  name       = "/${var.repository}/${local.module}/edge_db_edge/password"
  depends_on = [aws_ssm_parameter.edge_db_edge_password]
}

resource "aws_ssm_parameter" "edge_db_internal_server" {
  name  = "/${var.repository}/${local.module}/edge_db_internal/server"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_internal_server" {
  name       = "/${var.repository}/${local.module}/edge_db_internal/server"
  depends_on = [aws_ssm_parameter.edge_db_internal_server]
}

resource "aws_ssm_parameter" "edge_db_internal_port" {
  name  = "/${var.repository}/${local.module}/edge_db_internal/port"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_internal_port" {
  name       = "/${var.repository}/${local.module}/edge_db_internal/port"
  depends_on = [aws_ssm_parameter.edge_db_internal_port]
}

resource "aws_ssm_parameter" "edge_db_internal_user" {
  name  = "/${var.repository}/${local.module}/edge_db_internal/user"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_internal_user" {
  name       = "/${var.repository}/${local.module}/edge_db_internal/user"
  depends_on = [aws_ssm_parameter.edge_db_internal_user]
}

resource "aws_ssm_parameter" "edge_db_internal_password" {
  name  = "/${var.repository}/${local.module}/edge_db_internal/password"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_internal_password" {
  name       = "/${var.repository}/${local.module}/edge_db_internal/password"
  depends_on = [aws_ssm_parameter.edge_db_internal_password]
} 