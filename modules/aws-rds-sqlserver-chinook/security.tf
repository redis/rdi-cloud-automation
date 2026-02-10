# Creating the security group for the SQL Server instance
resource "aws_security_group" "producer_sg" {
  vpc_id = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # To be able to connect to SQL Server from the LB 
  ingress {
    from_port = var.db_port
    to_port   = var.db_port
    protocol  = "tcp"
    self      = true
  }
  # To be able to connect to SQL Server from allowed CIDR blocks
  # SECURITY: Only created if allowed_cidr_blocks is explicitly set
  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = var.db_port
      to_port     = var.db_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
      description = "SQL Server access from allowed CIDR blocks"
    }
  }
  tags = {
    Name = "producer-sg-sqlserver-${var.identifier}"
  }
}

