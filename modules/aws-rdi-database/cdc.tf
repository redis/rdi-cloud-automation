################################################################################
# CDC user provisioning via local-exec.
#
# These connect to the database through the NLB hostname, so terraform apply
# must run from a machine that can reach it. Two valid setups:
#   - public_access = true on this DB (NLB is internet-facing)
#   - terraform apply runs from inside the VPC (bastion, SSM Session Manager, VPN)
#
# Engines whose master user already has CDC privileges (Postgres family) skip
# this entirely — see engine_config.auto_create_rdi_user.
################################################################################

resource "null_resource" "create_rdi_user_mysql" {
  count = local.cfg.auto_create_rdi_user && contains(["aurora-mysql", "mysql", "mariadb"], var.engine) ? 1 : 0

  depends_on = [
    aws_rds_cluster_instance.this,
    aws_db_instance.this,
    module.privatelink,
    module.failover,
  ]

  triggers = {
    endpoint     = local.endpoint
    rdi_password = local.rdi_password
    nlb_hostname = module.privatelink.lb_hostname
  }

  provisioner "local-exec" {
    environment = {
      MYSQL_PWD = nonsensitive(var.db_password)
    }
    command = <<-EOF
      set -e
      echo "[${var.identifier}] Waiting for MySQL to be reachable..."
      sleep 30
      mysql -h ${module.privatelink.lb_hostname} -u ${local.cfg.master_username} -P ${local.port} <<SQL
      CREATE USER IF NOT EXISTS '${local.cfg.rdi_username}'@'%' IDENTIFIED BY '${local.rdi_password}';
      GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT, LOCK TABLES ON *.* TO '${local.cfg.rdi_username}'@'%';
      FLUSH PRIVILEGES;
      SQL
      echo "[${var.identifier}] ${local.cfg.rdi_username} user ready."
    EOF
  }
}

resource "null_resource" "load_init_sql_mysql" {
  count = var.init_sql_file != null && contains(["aurora-mysql", "mysql", "mariadb"], var.engine) && var.public_access ? 1 : 0

  depends_on = [
    null_resource.create_rdi_user_mysql,
  ]

  triggers = {
    sql_file_path = var.init_sql_file
    nlb_hostname  = module.privatelink.lb_hostname
  }

  provisioner "local-exec" {
    working_dir = path.root
    environment = {
      MYSQL_PWD = nonsensitive(var.db_password)
    }
    command = <<-EOF
      set -e
      echo "[${var.identifier}] Loading ${var.init_sql_file} into ${local.database_name}..."
      mysql -h ${module.privatelink.lb_hostname} -u ${local.cfg.master_username} -P ${local.port} ${local.database_name} < ${var.init_sql_file}
      echo "[${var.identifier}] SQL load complete."
    EOF
  }
}

resource "null_resource" "load_init_sql_postgres" {
  count = var.init_sql_file != null && contains(["aurora-postgres", "postgres"], var.engine) && var.public_access ? 1 : 0

  depends_on = [
    aws_rds_cluster_instance.this,
    aws_db_instance.this,
    module.privatelink,
    module.failover,
  ]

  triggers = {
    sql_file_path = var.init_sql_file
    nlb_hostname  = module.privatelink.lb_hostname
  }

  provisioner "local-exec" {
    working_dir = path.root
    environment = {
      PGPASSWORD = nonsensitive(var.db_password)
    }
    command = <<-EOF
      set -e
      echo "[${var.identifier}] Waiting for Postgres to be reachable..."
      sleep 30
      echo "[${var.identifier}] Loading ${var.init_sql_file} into ${local.database_name}..."
      psql -h ${module.privatelink.lb_hostname} -p ${local.port} -U ${local.cfg.master_username} -d ${local.database_name} -v ON_ERROR_STOP=1 -f ${var.init_sql_file}
      echo "[${var.identifier}] SQL load complete."
    EOF
  }
}

resource "null_resource" "load_init_sql_sqlserver" {
  count = var.init_sql_file != null && var.engine == "sqlserver" && var.public_access ? 1 : 0

  depends_on = [
    null_resource.create_rdi_user_sqlserver,
    module.failover,
  ]

  triggers = {
    sql_file_path = var.init_sql_file
    nlb_hostname  = module.privatelink.lb_hostname
  }

  provisioner "local-exec" {
    working_dir = path.root
    command     = <<-EOF
      set -e
      echo "[${var.identifier}] Loading ${var.init_sql_file} into ${local.database_name == null ? "master (script will create its own DB)" : local.database_name}..."
      sqlcmd -S ${module.privatelink.lb_hostname},${local.port} \
             -U ${local.cfg.master_username} \
             -P '${nonsensitive(var.db_password)}' \
             -d ${coalesce(local.database_name, "master")} \
             -b \
             -i ${var.init_sql_file}
      echo "[${var.identifier}] SQL load complete."
    EOF
  }
}

# Oracle init-sql loader. Requires sqlplus (Oracle Instant Client) on PATH.
# Connects directly to the SID set by `database_name` (defaults to ORCL).
# Oracle limits SID to 8 alphanumeric chars - don't try to use "inventory" here.
resource "null_resource" "load_init_sql_oracle" {
  count = var.init_sql_file != null && var.engine == "oracle" && var.public_access ? 1 : 0

  depends_on = [
    aws_db_instance.this,
    module.privatelink,
    module.failover,
  ]

  triggers = {
    sql_file_path = var.init_sql_file
    nlb_hostname  = module.privatelink.lb_hostname
  }

  provisioner "local-exec" {
    working_dir = path.root
    command     = <<-EOF
      set -e
      echo "[${var.identifier}] Waiting for Oracle listener to be reachable..."
      sleep 30
      echo "[${var.identifier}] Loading ${var.init_sql_file} into ${local.database_name}..."
      sqlplus -L -S '${local.cfg.master_username}/${nonsensitive(var.db_password)}@${module.privatelink.lb_hostname}:${local.port}/${local.database_name}' <<SQLPLUS_EOF
      WHENEVER SQLERROR EXIT FAILURE;
      SET ECHO ON;
      @${var.init_sql_file}
      EXIT;
      SQLPLUS_EOF
      echo "[${var.identifier}] SQL load complete."
    EOF
  }
}

resource "null_resource" "create_rdi_user_sqlserver" {
  count = local.cfg.auto_create_rdi_user && var.engine == "sqlserver" ? 1 : 0

  depends_on = [
    aws_db_instance.this,
    module.privatelink,
    module.failover,
  ]

  triggers = {
    endpoint     = local.endpoint
    rdi_password = local.rdi_password
    nlb_hostname = module.privatelink.lb_hostname
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -e
      echo "[${var.identifier}] Waiting for SQL Server to be reachable..."
      sleep 60
      sqlcmd -S ${module.privatelink.lb_hostname},${local.port} -U ${local.cfg.master_username} -P '${nonsensitive(var.db_password)}' -Q "
      IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '${local.cfg.rdi_username}')
      BEGIN
        CREATE LOGIN ${local.cfg.rdi_username} WITH PASSWORD = '${local.rdi_password}';
      END
      USE master;
      IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '${local.cfg.rdi_username}')
      BEGIN
        CREATE USER ${local.cfg.rdi_username} FOR LOGIN ${local.cfg.rdi_username};
      END
      ALTER SERVER ROLE [dbcreator] ADD MEMBER ${local.cfg.rdi_username};
      GRANT VIEW SERVER STATE TO ${local.cfg.rdi_username};
      GRANT VIEW ANY DEFINITION TO ${local.cfg.rdi_username};
      "
      echo "[${var.identifier}] ${local.cfg.rdi_username} user ready."
    EOF
  }
}
