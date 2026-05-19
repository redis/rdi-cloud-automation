# Example multi-database deployment.
#
# Every entry in `databases` produces an isolated source: its own NLB,
# PrivateLink endpoint service, Secrets Manager secret, security group,
# and failover Lambda. They all share the one VPC defined in `network`.
#
# Auto-creating a dedicated CDC user (debezium / rdi_user for MySQL & SQL Server)
# requires terraform to reach the database through its NLB. Either:
#   - set `public_access = true` for that DB, or
#   - run `terraform apply` from inside the VPC.
# Postgres engines use the master user directly and have no such requirement.
#
# Per-DB ARN fields control external access. Three states:
#   - omitted (null): closed - no external principal can access
#   - "*"           : open   - any AWS principal can access
#   - specific ARN  : scoped to that Redis Cloud subscription's principal
# A DB can be scoped to a different Redis Cloud subscription than its siblings.

region      = "eu-central-1"
aws_profile = "redislabs-dev-rdi"
name        = "rdi-ilian"

network = {
  vpc_cidr = "10.0.0.0/16"
  azs      = ["euc1-az1", "euc1-az2", "euc1-az3"]
}

# Inherited by every DB unless the DB sets its own allowed_cidrs.
# Replace with your office VPN egress CIDR(s).
allowed_cidrs = []

databases = {
  ############################################################################
  # Aurora MySQL x4 - "-01" opts into HA (2 instances). The rest stay at the
  # single-instance default to save cost in dev.
  ############################################################################

  "mysql-aurora-01" = { engine = "aurora-mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql", aurora_instance_count = 2 }
  "mysql-aurora-02" = { engine = "aurora-mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }
  "mysql-aurora-03" = { engine = "aurora-mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }
  "mysql-aurora-04" = { engine = "aurora-mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }

  ############################################################################
  # MySQL RDS x4
  ############################################################################

  "mysql-rds-01" = { engine = "mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }
  "mysql-rds-02" = { engine = "mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }
  "mysql-rds-03" = { engine = "mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }
  "mysql-rds-04" = { engine = "mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }

  ############################################################################
  # Aurora Postgres x4 - "-01" opts into HA (2 instances). The rest stay at
  # the single-instance default to save cost in dev.
  ############################################################################

  "postgres-aurora-01" = { engine = "aurora-postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql", aurora_instance_count = 2 }
  "postgres-aurora-02" = { engine = "aurora-postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  "postgres-aurora-03" = { engine = "aurora-postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  "postgres-aurora-04" = { engine = "aurora-postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }

  ############################################################################
  # Postgres RDS x4
  ############################################################################

  "postgres-rds-01" = { engine = "postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  "postgres-rds-02" = { engine = "postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  "postgres-rds-03" = { engine = "postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  "postgres-rds-04" = { engine = "postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }

  ############################################################################
  # SQL Server RDS x4 - script creates its own `inventory` DB. Requires `sqlcmd`.
  ############################################################################

  "sqlserver-rds-01" = { engine = "sqlserver", public_access = true, init_sql_file = "../sample-data-sets/sqlserver.sql" }
  "sqlserver-rds-02" = { engine = "sqlserver", public_access = true, init_sql_file = "../sample-data-sets/sqlserver.sql" }
  "sqlserver-rds-03" = { engine = "sqlserver", public_access = true, init_sql_file = "../sample-data-sets/sqlserver.sql" }
  "sqlserver-rds-04" = { engine = "sqlserver", public_access = true, init_sql_file = "../sample-data-sets/sqlserver.sql" }

  ############################################################################
  # Oracle RDS x4 - SID stays at default "ORCL" (8-char limit). Tables in admin schema.
  # Requires `sqlplus` (Oracle Instant Client).
  ############################################################################

  "oracle-rds-01" = { engine = "oracle", public_access = true, init_sql_file = "../sample-data-sets/oracle.sql" }
  "oracle-rds-02" = { engine = "oracle", public_access = true, init_sql_file = "../sample-data-sets/oracle.sql" }
  "oracle-rds-03" = { engine = "oracle", public_access = true, init_sql_file = "../sample-data-sets/oracle.sql" }
  "oracle-rds-04" = { engine = "oracle", public_access = true, init_sql_file = "../sample-data-sets/oracle.sql" }

  ############################################################################
  # MariaDB RDS x4 - uses its own dump (MariaDB 10.11 doesn't support
  # MySQL 8.0's utf8mb4_0900_ai_ci collation).
  ############################################################################

  "mariadb-rds-01" = { engine = "mariadb", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mariadb.sql" }
  "mariadb-rds-02" = { engine = "mariadb", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mariadb.sql" }
  "mariadb-rds-03" = { engine = "mariadb", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mariadb.sql" }
  "mariadb-rds-04" = { engine = "mariadb", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mariadb.sql" }
}
