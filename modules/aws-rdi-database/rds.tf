################################################################################
# Aurora cluster path (engine type = "aurora")
################################################################################

resource "aws_rds_cluster" "this" {
  count = local.is_aurora ? 1 : 0

  cluster_identifier              = "aurora-${var.identifier}"
  engine                          = local.cfg.engine
  engine_version                  = local.engine_version
  database_name                   = local.database_name
  master_username                 = local.cfg.master_username
  master_password                 = var.db_password
  port                            = local.port
  backup_retention_period         = 5
  preferred_backup_window         = "07:00-09:00"
  skip_final_snapshot             = true
  db_subnet_group_name            = var.network.database_subnet_group_name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name
  apply_immediately               = true
  storage_encrypted               = true

  tags = {
    Name = "aurora-${var.identifier}"
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = local.is_aurora ? var.aurora_instance_count : 0

  identifier           = "${var.identifier}-${count.index}"
  cluster_identifier   = aws_rds_cluster.this[0].id
  instance_class       = local.instance_class
  engine               = aws_rds_cluster.this[0].engine
  engine_version       = aws_rds_cluster.this[0].engine_version
  db_subnet_group_name = var.network.database_subnet_group_name
}

resource "aws_rds_cluster_parameter_group" "this" {
  count = local.is_aurora ? 1 : 0

  name   = var.identifier
  family = local.cfg.parameter_group_family

  dynamic "parameter" {
    for_each = local.cfg.parameter_group_params
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }
}

################################################################################
# Standalone RDS instance path (engine type = "rds")
################################################################################

resource "aws_db_instance" "this" {
  count = local.is_aurora ? 0 : 1

  identifier     = "rds-${var.identifier}"
  engine         = local.cfg.engine
  engine_version = local.engine_version
  instance_class = local.instance_class
  username       = local.cfg.master_username
  password       = var.db_password
  port           = local.port
  db_name        = local.database_name
  license_model  = local.cfg.license_model

  allocated_storage     = local.cfg.engine == "sqlserver-se" ? 100 : 20
  max_allocated_storage = local.cfg.engine == "sqlserver-se" ? 200 : 100
  storage_type          = "gp3"
  storage_encrypted     = true

  multi_az = true

  backup_retention_period = 7
  backup_window           = "07:00-09:00"
  skip_final_snapshot     = true

  db_subnet_group_name   = var.network.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  parameter_group_name = aws_db_parameter_group.this[0].name
  apply_immediately    = true

  tags = {
    Name = "rds-${var.identifier}"
  }
}

resource "aws_db_parameter_group" "this" {
  count = local.is_aurora ? 0 : 1

  name   = var.identifier
  family = local.cfg.parameter_group_family

  dynamic "parameter" {
    for_each = local.cfg.parameter_group_params
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }
}
