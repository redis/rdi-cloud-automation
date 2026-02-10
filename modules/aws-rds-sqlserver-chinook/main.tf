# SQL Server RDS instance (not Aurora - SQL Server doesn't support Aurora)
# Using Multi-AZ for high availability
resource "aws_db_instance" "sqlserver" {
  identifier     = "rds-sqlserver-${var.identifier}"
  engine         = "sqlserver-se"  # SQL Server Standard Edition
  engine_version = data.aws_rds_engine_version.sqlserver.version
  instance_class = "db.t3.xlarge"  # SQL Server requires larger instances

  # Database configuration
  db_name  = null  # SQL Server doesn't support db_name parameter
  username = "sa"
  password = var.db_password
  port     = var.db_port

  # Storage configuration
  allocated_storage     = 100  # Minimum for SQL Server
  max_allocated_storage = 200  # Enable storage autoscaling
  storage_type          = "gp3"
  storage_encrypted     = true

  # High availability
  multi_az = true

  # Backup configuration
  backup_retention_period = 7
  backup_window           = "07:00-09:00"
  skip_final_snapshot     = true

  # Network configuration
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.producer_sg.id]
  publicly_accessible    = false

  # Parameter group for CDC/Change Tracking
  parameter_group_name = aws_db_parameter_group.default.name

  # Apply changes immediately
  apply_immediately = true

  # License model for SQL Server
  license_model = "license-included"

  tags = {
    Name = "rds-sqlserver-${var.identifier}"
  }
}

# Parameter group for SQL Server with Change Tracking enabled
resource "aws_db_parameter_group" "default" {
  name   = "${var.identifier}-sqlserver"
  family = "sqlserver-se-16.0"

  # Enable Change Tracking for CDC
  parameter {
    name  = "contained database authentication"
    value = "1"
  }

  tags = {
    Name = "${var.identifier}-sqlserver-params"
  }
}

