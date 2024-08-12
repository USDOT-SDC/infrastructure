data "aws_ami" "gitlab_ee_16_10" {
  # executable_users = ["self"]
  most_recent = true
  name_regex  = "^GitLab EE 16.10"
  owners      = ["782774275127"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# output "gitlab" {
#   value = data.aws_ami.gitlab_ee_16_10
# }

resource "aws_instance" "gitlab" {
  ami                  = data.aws_ami.gitlab_ee_16_10.id
  availability_zone    = var.common.network.subnet_support.availability_zone
  iam_instance_profile = aws_iam_instance_profile.gitlab.name
  instance_type        = "c7a.xlarge"
  key_name             = "ost-sdc-${var.common.environment}"
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      ami,
      root_block_device,
      tags["Name"]
    ]
  }
  root_block_device {
    // Modifying any of the root_block_device settings other than volume_size or tags requires resource replacement.
    // (Formats the C: drive)
    volume_size = 30
    tags        = merge(local.common_tags, var.default_tags)
  }
  vpc_security_group_ids = [
    var.common.network.fms_security_group.id,
    aws_security_group.gitlab.id
  ]
  subnet_id = var.common.network.subnet_support.id
  tags = merge(
    local.common_tags,
    {
      Name     = data.aws_ami.gitlab_ee_16_10.name
      Role     = "GitLab-Server"
      AMI_Name = data.aws_ami.gitlab_ee_16_10.name
    }
  )
}

resource "aws_security_group" "gitlab" {
  name        = "${var.common.configuration_slug}.gitlab"
  description = "Allow HTTP, HTTPS and SSH inbound traffic and all outbound traffic"
  vpc_id      = var.common.network.vpc.id
  egress {
    description = "Allow all egress"
    cidr_blocks = ["0.0.0.0/0"]
    to_port     = 0
    from_port   = 0
    protocol    = -1 # All protocols
  }
  ingress {
    description = "HTTP"
    cidr_blocks = var.common.network.vpc.cidr_block_associations[*].cidr_block
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    description = "HTTPS"
    cidr_blocks = var.common.network.vpc.cidr_block_associations[*].cidr_block
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    description = "SSH"
    cidr_blocks = var.common.network.vpc.cidr_block_associations[*].cidr_block
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  tags = local.common_tags
}

# resource "aws_lb" "gitlab" {
#   name                             = "${var.common.configuration_slug}-gitlab-net"
#   enable_cross_zone_load_balancing = true
#   internal                         = true
#   load_balancer_type               = "network"
#   security_groups                  = [aws_security_group.gitlab.id]
#   subnets = [
#     var.common.network.subnet_support.id,
#     var.common.network.subnet_researcher.id
#   ]
#   depends_on = [aws_security_group.gitlab]
#   tags       = merge(local.common_tags, { Name = "GitLab NLB New" })
# }

# resource "aws_lb_listener" "gitlab_80_tcp" {
#   load_balancer_arn = aws_lb.gitlab.arn
#   port              = "80"
#   protocol          = "TCP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.gitlab_80_tcp.arn
#   }
#   tags = local.common_tags
# }

# resource "aws_lb_target_group" "gitlab_80_tcp" {
#   name     = "${var.common.configuration_slug}-gitlab-net-80-tcp"
#   port     = 80
#   protocol = "TCP"
#   vpc_id   = var.common.network.vpc.id
#   health_check {
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     port                = 80
#     protocol            = "HTTP"
#     path                = "/-/readiness?all=1"
#   }
#   tags = merge(local.common_tags, { Name = "GitLab 80 TCP" })
# }

# resource "aws_lb_listener" "gitlab_22_tcp" {
#   load_balancer_arn = aws_lb.gitlab.arn
#   port              = "22"
#   protocol          = "TCP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.gitlab_22_tcp.arn
#   }
#   tags = local.common_tags
# }

# resource "aws_lb_target_group" "gitlab_22_tcp" {
#   name     = "${var.common.configuration_slug}-gitlab-net-22-tcp"
#   port     = 22
#   protocol = "TCP"
#   vpc_id   = var.common.network.vpc.id
#   health_check {
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     port                = 22
#     protocol            = "TCP"
#   }
#   tags = merge(local.common_tags, { Name = "GitLab 22 TCP" })
# }

# resource "aws_lb_listener" "gitlab_443_tls" {
#   load_balancer_arn = aws_lb.gitlab.arn
#   port              = "443"
#   protocol          = "TLS"
#   certificate_arn   = "arn:aws:acm:us-east-1:505135622787:certificate/907238e5-e4fd-4a45-becf-743289908c11"
#   alpn_policy       = "HTTP2Preferred"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.gitlab_443_tls.arn
#   }
#   tags = local.common_tags
# }

# resource "aws_lb_target_group" "gitlab_443_tls" {
#   name     = "${var.common.configuration_slug}-gitlab-net-443-tls"
#   port     = 443
#   protocol = "TLS"
#   vpc_id   = var.common.network.vpc.id
#   health_check {
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     port                = 22
#     protocol            = "HTTPS"
#     path                = "/-/readiness?all=1"
#   }
#   tags = merge(local.common_tags, { Name = "GitLab 443 TLS" })
# }
