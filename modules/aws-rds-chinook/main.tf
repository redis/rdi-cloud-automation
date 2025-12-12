resource "aws_rds_cluster" "postgresql" {
  cluster_identifier              = "aurora-${var.identifier}"
  engine                          = "aurora-postgresql"
  database_name                   = "chinook"
  master_username                 = "postgres"
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
  name   = var.identifier
  family = "aurora-postgresql17"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                = 2
  identifier           = "${var.identifier}-${count.index}"
  cluster_identifier   = aws_rds_cluster.postgresql.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.postgresql.engine
  engine_version       = aws_rds_cluster.postgresql.engine_version
  db_subnet_group_name = module.vpc.database_subnet_group_name
}
