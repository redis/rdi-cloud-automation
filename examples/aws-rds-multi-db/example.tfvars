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
allowed_cidrs = ["62.67.249.178/32"]

# Optional EC2 bastion with mysql/psql/sqlcmd/sqlplus pre-installed.
# When enabled, every DB SG also accepts ingress from the bastion, so you can
# flip per-DB `public_access = false` and reach the DBs only via the bastion.
# SSH password is random-generated; read with `terraform output -raw bastion_password`.
bastion = {
  enabled           = true
  instance_type     = "t3.small"
  allowed_ssh_cidrs = ["0.0.0.0/0"] # SSH open to the world; password auth is the gate.
}

databases = {
  ############################################################################
  # Aurora MySQL x4 - "-01" opts into HA (2 instances). The rest stay at the
  # single-instance default to save cost in dev.
  ############################################################################

  "mysql-aurora-01" = {
    engine = "aurora-mysql",
    public_access = true,
    database_name = "inventory",
    init_sql_file = "../sample-data-sets/mysql.sql", aurora_instance_count = 1,
    allowed_cidrs = ["0.0.0.0/0"],
    redis_privatelink_arn = [
      "arn:aws:iam::364960782546:role/redis-data-pipeline",
      "arn:aws:iam::597729803865:role/redis-data-pipeline",
      "arn:aws:iam::473387995565:role/redis-data-pipeline",
      "arn:aws:iam::655177116670:role/redis-data-pipeline",
    ],
    redis_secrets_arn     = [
      "arn:aws:iam::364960782546:role/redis-data-pipeline-secrets-role",
      "arn:aws:iam::597729803865:role/redis-data-pipeline-secrets-role",
      "arn:aws:iam::473387995565:role/redis-data-pipeline-secrets-role",
      "arn:aws:iam::655177116670:role/redis-data-pipeline-secrets-role",
    ]
  }
  # "mysql-aurora-02" = {
  #   engine = "aurora-mysql",
  #   public_access = true,
  #   database_name = "inventory",
  #   init_sql_file = "../sample-data-sets/mysql.sql",
  #   allowed_cidrs = ["0.0.0.0/0"],
  #   redis_privatelink_arn = "arn:aws:iam::673515369491:role/redis-data-pipeline",
  #   redis_secrets_arn     = "arn:aws:iam::673515369491:role/redis-data-pipeline-secrets-role"
  # }
  # "mysql-aurora-03" = {
  #   engine = "aurora-mysql",
  #   public_access = true,
  #   database_name = "inventory",
  #   init_sql_file = "../sample-data-sets/mysql.sql",
  #   allowed_cidrs = ["0.0.0.0/0"],
  #   redis_privatelink_arn = "arn:aws:iam::027047015249:role/redis-data-pipeline",
  #   redis_secrets_arn     = "arn:aws:iam::027047015249:role/redis-data-pipeline-secrets-role"
  # }
  # "mysql-aurora-04" = {
  #   engine = "aurora-mysql",
  #   public_access = true,
  #   database_name = "inventory",
  #   init_sql_file = "../sample-data-sets/mysql.sql",
  #   redis_privatelink_arn = "arn:aws:iam::541227053969:role/redis-data-pipeline",
  #   redis_secrets_arn     = "arn:aws:iam::541227053969:role/redis-data-pipeline-secrets-role"
  # }
  #


  # ############################################################################
  # # MySQL RDS x4
  # ############################################################################
  #
  "mysql-rds-01" = {
    engine = "mysql",
    public_access = true,
    database_name = "inventory",
    init_sql_file = "../sample-data-sets/mysql.sql",
    allowed_cidrs = ["0.0.0.0/0"],
    # redis_privatelink_arn = "arn:aws:iam::500511648814:role/redis-data-pipeline",
    redis_secrets_arn     = [
      "arn:aws:iam::500511648814:role/redis-data-pipeline-secrets-role",
      "arn:aws:iam::423405487100:role/redis-data-pipeline-secrets-role"
    ]
  }
  # "mysql-rds-02" = { engine = "mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }
  # "mysql-rds-03" = { engine = "mysql", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mysql.sql" }
  # "mysql-rds-04" = {
  #   engine = "mysql",
  #   public_access = true,
  #   database_name = "inventory",
  #   init_sql_file = "../sample-data-sets/mysql.sql",
  #   redis_privatelink_arn = "arn:aws:iam::509820673354:role/redis-data-pipeline",
  #   redis_secrets_arn     = "arn:aws:iam::509820673354:role/redis-data-pipeline-secrets-role"
  # }
  #


  # ############################################################################
  # # Aurora Postgres x4 - "-01" opts into HA (2 instances). The rest stay at
  # # the single-instance default to save cost in dev.
  # ############################################################################
  #
  "postgres-aurora-01" = {
    engine = "aurora-postgres",
    public_access = true,
    database_name = "inventory",
    init_sql_file = "../sample-data-sets/postgres.sql",
    # aurora_instance_count = 2,
    # redis_privatelink_arn = "*",
    redis_privatelink_arn = "arn:aws:iam::004619892571:role/redis-data-pipeline",
    redis_secrets_arn     = "arn:aws:iam::004619892571:role/redis-data-pipeline-secrets-role"
  }
  # "postgres-aurora-02" = { engine = "aurora-postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  # "postgres-aurora-03" = { engine = "aurora-postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  # "postgres-aurora-04" = { engine = "aurora-postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  #


  # ############################################################################
  # # Postgres RDS x4
  # ############################################################################
  #
  "postgres-rds-01" = {
    engine                = "postgres"
    public_access         = true
    database_name         = "inventory"
    init_sql_file         = "../sample-data-sets/postgres.sql"
    # redis_privatelink_arn = "arn:aws:iam::004619892571:role/redis-data-pipeline"
    # redis_secrets_arn     = "arn:aws:iam::004619892571:role/redis-data-pipeline-secrets-role"
  }
  # "postgres-rds-02" = { engine = "postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  # "postgres-rds-03" = { engine = "postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  # "postgres-rds-04" = { engine = "postgres", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/postgres.sql" }
  #


  # ############################################################################
  # # SQL Server RDS x4 - script creates its own `inventory` DB. Requires `sqlcmd`.
  # ############################################################################
  #
  "sqlserver-rds-01" = { engine = "sqlserver", public_access = true, init_sql_file = "../sample-data-sets/sqlserver.sql" }
  # "sqlserver-rds-02" = {
  #   engine = "sqlserver",
  #   public_access = true,
  #   init_sql_file = "../sample-data-sets/sqlserver.sql",
  #   redis_privatelink_arn = "arn:aws:iam::655177116670:role/redis-data-pipeline",
  #   redis_secrets_arn     = "arn:aws:iam::655177116670:role/redis-data-pipeline-secrets-role"
  # }
  # "sqlserver-rds-03" = {
  #   engine = "sqlserver",
  #   public_access = true,
  #   init_sql_file = "../sample-data-sets/sqlserver.sql",
  #   redis_privatelink_arn = "arn:aws:iam::304242047711:role/redis-data-pipeline",
  #   redis_secrets_arn     = "arn:aws:iam::304242047711:role/redis-data-pipeline-secrets-role"
  #
  # }
  # "sqlserver-rds-04" = {
  #   engine = "sqlserver",
  #   public_access = true,
  #   init_sql_file = "../sample-data-sets/sqlserver.sql",
  #   redis_privatelink_arn = "arn:aws:iam::178886967291:role/redis-data-pipeline",
  #   redis_secrets_arn     = "arn:aws:iam::178886967291:role/redis-data-pipeline-secrets-role"
  # }
  #


  # ############################################################################
  # # Oracle RDS x4 - SID stays at default "ORCL" (8-char limit). Tables in admin schema.
  # # Requires `sqlplus` (Oracle Instant Client).
  # ############################################################################
  #
  "oracle-rds-01" = {
    engine = "oracle",
    public_access = true,
    init_sql_file = "../sample-data-sets/oracle.sql",
    redis_privatelink_arn = "arn:aws:iam::500511648814:role/redis-data-pipeline",
    redis_secrets_arn     = "arn:aws:iam::500511648814:role/redis-data-pipeline-secrets-role"

  }
  # "oracle-rds-02" = { engine = "oracle", public_access = true, init_sql_file = "../sample-data-sets/oracle.sql" }
  # "oracle-rds-03" = { engine = "oracle", public_access = true, init_sql_file = "../sample-data-sets/oracle.sql" }
  # "oracle-rds-04" = { engine = "oracle", public_access = true, init_sql_file = "../sample-data-sets/oracle.sql" }
  #


  # ############################################################################
  # # MariaDB RDS x4 - uses its own dump (MariaDB 10.11 doesn't support
  # # MySQL 8.0's utf8mb4_0900_ai_ci collation).
  # ############################################################################
  #
  "mariadb-rds-01" = {
    engine = "mariadb",
    public_access = true,
    database_name = "inventory",
    init_sql_file = "../sample-data-sets/mariadb.sql",
    # redis_privatelink_arn = "arn:aws:iam::549955691546:role/redis-data-pipeline",
    # redis_secrets_arn     = "arn:aws:iam::549955691546:role/redis-data-pipeline-secrets-role"
  }
  # "mariadb-rds-02" = {
  #   engine = "mariadb",
  #   public_access = true,
  #   database_name = "inventory",
  #   init_sql_file = "../sample-data-sets/mariadb.sql",
  #   redis_privatelink_arn = "arn:aws:iam::444702081592:role/redis-data-pipeline",
  #   redis_secrets_arn     = "arn:aws:iam::444702081592:role/redis-data-pipeline-secrets-role"
  # }
  # "mariadb-rds-03" = { engine = "mariadb", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mariadb.sql" }
  # "mariadb-rds-04" = { engine = "mariadb", public_access = true, database_name = "inventory", init_sql_file = "../sample-data-sets/mariadb.sql" }
}
