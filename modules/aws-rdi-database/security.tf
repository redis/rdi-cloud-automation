resource "aws_security_group" "this" {
  name        = var.identifier
  description = "RDI source database access for ${var.identifier}"
  vpc_id      = var.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Self-rule lets the NLB (which shares this SG) reach the RDS targets.
  ingress {
    description = "NLB to RDS (same SG)"
    from_port   = local.port
    to_port     = local.port
    protocol    = "tcp"
    self        = true
  }

  dynamic "ingress" {
    for_each = var.public_access && length(var.allowed_cidrs) > 0 ? [1] : []
    content {
      description = "Public access from allowed CIDRs"
      from_port   = local.port
      to_port     = local.port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidrs
    }
  }

  dynamic "ingress" {
    for_each = length(var.client_security_group_ids) > 0 ? [1] : []
    content {
      description     = "In-VPC client (bastion) access"
      from_port       = local.port
      to_port         = local.port
      protocol        = "tcp"
      security_groups = var.client_security_group_ids
    }
  }

  tags = {
    Name = var.identifier
  }
}
