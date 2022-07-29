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

resource "aws_ssm_parameter" "edge_db_edge_dbname" {
  name  = "/${var.repository}/${local.module}/edge_db_edge/dbname"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_edge_dbname" {
  name       = "/${var.repository}/${local.module}/edge_db_edge/dbname"
  depends_on = [aws_ssm_parameter.edge_db_edge_dbname]
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

resource "aws_ssm_parameter" "edge_db_edge_admin" {
  name  = "/${var.repository}/${local.module}/edge_db_edge/admin"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_edge_admin" {
  name       = "/${var.repository}/${local.module}/edge_db_edge/admin"
  depends_on = [aws_ssm_parameter.edge_db_edge_admin]
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

resource "aws_ssm_parameter" "edge_db_edge_sg_id" {
  name  = "/${var.repository}/${local.module}/edge_db_edge/sg_id"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_edge_sg_id" {
  name       = "/${var.repository}/${local.module}/edge_db_edge/sg_id"
  depends_on = [aws_ssm_parameter.edge_db_edge_sg_id]
}

resource "aws_ssm_parameter" "edge_db_internal_dbname" {
  name  = "/${var.repository}/${local.module}/edge_db_internal/dbname"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_internal_dbname" {
  name       = "/${var.repository}/${local.module}/edge_db_internal/dbname"
  depends_on = [aws_ssm_parameter.edge_db_internal_dbname]
# }

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

resource "aws_ssm_parameter" "edge_db_internal_admin" {
  name  = "/${var.repository}/${local.module}/edge_db_internal/admin"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_internal_admin" {
  name       = "/${var.repository}/${local.module}/edge_db_internal/admin"
  depends_on = [aws_ssm_parameter.edge_db_internal_admin]
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

resource "aws_ssm_parameter" "edge_db_internal_sg_id" {
  name  = "/${var.repository}/${local.module}/edge_db_internal/sg_id"
  type  = "String"
  value = "_"
  lifecycle {
    ignore_changes = [value]
  }
  tags = local.tags
}
data "aws_ssm_parameter" "edge_db_internal_sg_id" {
  name       = "/${var.repository}/${local.module}/edge_db_internal/sg_id"
  depends_on = [aws_ssm_parameter.edge_db_internal_sg_id]
}