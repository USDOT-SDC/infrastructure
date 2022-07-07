resource "aws_security_group" "aurora" {
  name        = "${local.module}_aurora_role"
  description = "Edge DB Aurora Security Group"
  vpc_id      = var.common.network.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "aurora_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [data.aws_subnet.researchers.cidr_block]
  security_group_id = aws_security_group.aurora.id
}

resource "aws_security_group" "glue_aurora" {
  name        = "${local.module}_glue_aurora_sg"
  description = "Allow glue to connect to aurora edge-db"
  vpc_id      = var.common.network.vpc.id
  tags = local.tags
}

resource "aws_security_group_rule" "glue_aurora_ingress_self" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.glue_aurora.id
}

resource "aws_security_group_rule" "glue_aurora_egress_self" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.glue_aurora.id
}

resource "aws_security_group_rule" "glue_aurora_egress_all" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.glue_aurora.id
}