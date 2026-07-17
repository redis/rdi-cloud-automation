locals {
  # Single source of truth for every engine-specific value.
  # type = "aurora" | "rds" — selects which resource path to take.
  # auto_create_rdi_user gates the null_resource that creates a dedicated CDC user.
  engine_config = {
    "aurora-postgres" = {
      type                   = "aurora"
      engine                 = "aurora-postgresql"
      engine_major_version   = "17"
      parameter_group_family = "aurora-postgresql17"
      default_port           = 5432
      default_instance_class = "db.t4g.medium"
      master_username        = "postgres"
      rdi_username           = "postgres"
      auto_create_rdi_user   = false
      default_database_name  = "chinook"
      license_model          = null
      parameter_group_params = [
        { name = "rds.logical_replication", value = "1", apply_method = "pending-reboot" }
      ]
    }
    "aurora-mysql" = {
      type                   = "aurora"
      engine                 = "aurora-mysql"
      engine_major_version   = "8.0"
      parameter_group_family = "aurora-mysql8.0"
      default_port           = 3306
      default_instance_class = "db.t4g.medium"
      master_username        = "admin"
      rdi_username           = "debezium"
      auto_create_rdi_user   = true
      default_database_name  = "chinook"
      license_model          = null
      parameter_group_params = [
        { name = "binlog_format", value = "ROW", apply_method = "pending-reboot" },
        { name = "binlog_row_image", value = "FULL", apply_method = "pending-reboot" },
        { name = "gtid-mode", value = "ON", apply_method = "pending-reboot" },
        { name = "enforce_gtid_consistency", value = "ON", apply_method = "pending-reboot" },
        # Effectively disable host-block anti-brute-force: the NLB presents a single source IP,
        # so internet scans against a public_access DB easily exhaust the default of 100.
        { name = "max_connect_errors", value = "1000000", apply_method = "pending-reboot" }
      ]
    }
    "postgres" = {
      type                   = "rds"
      engine                 = "postgres"
      engine_major_version   = "16"
      parameter_group_family = "postgres16"
      default_port           = 5432
      default_instance_class = "db.t4g.medium"
      master_username        = "postgres"
      rdi_username           = "postgres"
      auto_create_rdi_user   = false
      default_database_name  = "chinook"
      license_model          = null
      parameter_group_params = [
        { name = "rds.logical_replication", value = "1", apply_method = "pending-reboot" }
      ]
    }
    "mysql" = {
      type                   = "rds"
      engine                 = "mysql"
      engine_major_version   = "8.0"
      parameter_group_family = "mysql8.0"
      default_port           = 3306
      default_instance_class = "db.t4g.medium"
      master_username        = "admin"
      rdi_username           = "debezium"
      auto_create_rdi_user   = true
      default_database_name  = "chinook"
      license_model          = null
      parameter_group_params = [
        { name = "binlog_format", value = "ROW", apply_method = "immediate" },
        { name = "binlog_row_image", value = "FULL", apply_method = "immediate" },
        { name = "max_connect_errors", value = "1000000", apply_method = "immediate" }
      ]
    }
    "mariadb" = {
      type                   = "rds"
      engine                 = "mariadb"
      engine_major_version   = "10.11"
      parameter_group_family = "mariadb10.11"
      default_port           = 3306
      default_instance_class = "db.t4g.medium"
      master_username        = "admin"
      rdi_username           = "debezium"
      auto_create_rdi_user   = true
      default_database_name  = "chinook"
      license_model          = null
      # MariaDB treats these as static; MySQL treats them as dynamic. pending-reboot works for both.
      parameter_group_params = [
        { name = "binlog_format", value = "ROW", apply_method = "pending-reboot" },
        { name = "binlog_row_image", value = "FULL", apply_method = "pending-reboot" },
        { name = "max_connect_errors", value = "1000000", apply_method = "pending-reboot" }
      ]
    }
    "oracle" = {
      type                   = "rds"
      engine                 = "oracle-se2"
      engine_major_version   = "19"
      parameter_group_family = "oracle-se2-19"
      default_port           = 1521
      default_instance_class = "db.t3.medium"
      master_username        = "admin"
      rdi_username           = "admin"
      auto_create_rdi_user   = false
      default_database_name  = "ORCL"
      license_model          = "license-included"
      parameter_group_params = []
    }
    "sqlserver" = {
      type                   = "rds"
      engine                 = "sqlserver-se"
      engine_major_version   = "16.00"
      parameter_group_family = "sqlserver-se-16.0"
      default_port           = 1433
      default_instance_class = "db.t3.xlarge"
      master_username        = "sa"
      rdi_username           = "rdi_user"
      auto_create_rdi_user   = true
      default_database_name  = null
      license_model          = "license-included"
      parameter_group_params = [
        { name = "contained database authentication", value = "1" }
      ]
    }
  }

  cfg            = local.engine_config[var.engine]
  port           = coalesce(var.port, local.cfg.default_port)
  instance_class = coalesce(var.instance_class, local.cfg.default_instance_class)
  is_aurora      = local.cfg.type == "aurora"

  redis_secrets_arns = (
    var.redis_secrets_arn == null ? [] :
    can(tolist(var.redis_secrets_arn)) ? [for arn in tolist(var.redis_secrets_arn) : tostring(arn)] :
    [tostring(var.redis_secrets_arn)]
  )

  redis_privatelink_arns = (
    var.redis_privatelink_arn == null ? [] :
    can(tolist(var.redis_privatelink_arn)) ? [for arn in tolist(var.redis_privatelink_arn) : tostring(arn)] :
    [tostring(var.redis_privatelink_arn)]
  )

  # Caller can override the engine's default database name (e.g. set "inventory" for MySQL).
  # SQL Server doesn't accept db_name at creation time, so its default is null and shouldn't be overridden.
  database_name = var.database_name != null ? var.database_name : local.cfg.default_database_name

  engine_version = coalesce(var.engine_version, data.aws_rds_engine_version.this.version)

  # Resolve outputs from whichever resource path (Aurora cluster or single RDS instance) was taken.
  endpoint        = local.is_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
  rds_arn         = local.is_aurora ? aws_rds_cluster.this[0].arn : aws_db_instance.this[0].arn
  rds_source_id   = local.is_aurora ? aws_rds_cluster.this[0].cluster_identifier : aws_db_instance.this[0].identifier
  rds_source_type = local.is_aurora ? "db-cluster" : "db-instance"

  # When a dedicated CDC user is created, RDI uses its password; otherwise it uses the master.
  rdi_password = local.cfg.auto_create_rdi_user ? random_password.rdi[0].result : var.db_password
}
