# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.identifier}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    {
      Name        = "${var.identifier}-db-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for RDS Aurora
resource "aws_security_group" "rds" {
  name        = "${var.identifier}-rds-sg"
  description = "Security group for RDS Aurora PostgreSQL cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Adjust this based on your VPC CIDR
  }

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port                = var.db_port
      to_port                 = var.db_port
      protocol                = "tcp"
      source_security_group_id = ingress.value
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.identifier}-rds-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# RDS Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier          = "${var.identifier}-aurora-cluster"
  engine                       = "aurora-postgresql"
  engine_version               = var.db_engine_version
  database_name                = var.db_name
  master_username             = var.db_master_username
  master_password             = var.db_master_password
  port                         = var.db_port
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection          = false # Set to true in production

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(
    {
      Name        = "${var.identifier}-aurora-cluster"
      Environment = var.environment
    },
    var.tags
  )
}

# RDS Aurora PostgreSQL Cluster Instance
resource "aws_rds_cluster_instance" "main" {
  identifier         = "${var.identifier}-aurora-instance-1"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  tags = merge(
    {
      Name        = "${var.identifier}-aurora-instance-1"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.identifier}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.identifier}-rds-monitoring-role"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Role Policy for Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

