resource "aws_rds_cluster" "mysql" {
  cluster_identifier              = "aurora-mysql-${var.identifier}"
  engine                          = "aurora-mysql"
  engine_version                  = data.aws_rds_engine_version.mysql.version
  database_name                   = "chinook"
  master_username                 = "admin"
  master_password                 = var.db_password
  backup_retention_period         = 5
  preferred_backup_window         = "07:00-09:00"
  skip_final_snapshot             = true
  db_subnet_group_name            = module.vpc.database_subnet_group_name
  vpc_security_group_ids          = [aws_security_group.producer_sg.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default.name
  apply_immediately               = true
}

resource "aws_rds_cluster_parameter_group" "default" {
  name   = "${var.identifier}-mysql"
  family = "aurora-mysql8.0"

  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "binlog_row_image"
    value        = "FULL"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "gtid-mode"
    value        = "ON"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "enforce_gtid_consistency"
    value        = "ON"
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                = 2
  identifier           = "${var.identifier}-mysql-${count.index}"
  cluster_identifier   = aws_rds_cluster.mysql.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.mysql.engine
  engine_version       = aws_rds_cluster.mysql.engine_version
  db_subnet_group_name = module.vpc.database_subnet_group_name
}

