# Multi-database deployment example.
#
# Copy this file before using it and replace every value marked "example" with
# values for your environment. The AWS account IDs below are documentation-only
# placeholders; they do not identify real Redis Cloud subscriptions.

region = "eu-central-1"

# Optional. Leave null to use the standard AWS credential chain (for example,
# AWS_PROFILE or environment credentials), or set this to a local profile name.
aws_profile = null

name = "rdi-multi-db-example"

# Availability Zone IDs are stable across AWS accounts, unlike AZ names.
# Replace these IDs if you choose a different region.
network = {
  vpc_cidr = "10.0.0.0/16"
  azs      = ["euc1-az1", "euc1-az2", "euc1-az3"]
}

# Default direct-access allowlist for public databases and SSH access to the
# bastion. 203.0.113.0/24 is reserved for documentation and will not provide
# real access; replace it with your VPN or workstation egress CIDR.
allowed_cidrs = ["203.0.113.10/32"]

# Defaults inherited by databases that do not set per-database ARN values.
# Use the principal ARNs shown by Redis Cloud for your subscription.
redis_privatelink_arn = "arn:aws:iam::111122223333:role/redis-data-pipeline"
redis_secrets_arn     = "arn:aws:iam::111122223333:role/redis-data-pipeline-secrets-role"

# Optional shared operations host with mysql, psql, sqlcmd, and sqlplus.
# Set enabled = true to create it. Its SSH allowlist defaults to allowed_cidrs.
bastion = {
  enabled       = false
  instance_type = "t3.small"
  # allowed_ssh_cidrs = ["203.0.113.10/32"] # Configure this if bastion is enabled
}

databases = {
  # Every entry below creates a database and its supporting infrastructure.
  # Remove entries you do not need; Oracle and SQL Server are notably costly.

  # Minimal configuration: inherits the top-level CIDRs and Redis Cloud ARNs.
  # public_access is enabled so Terraform can create the MySQL CDC user when
  # Terraform is run outside the VPC.
  mysql = {
    engine        = "mysql"
    public_access = true
    database_name = "inventory"
    init_sql_file = "../sample-data-sets/mysql.sql"
  }

  # Aurora example. Uncomment any optional override you need.
  aurora_postgres = {
    engine = "aurora-postgres"
    # engine_version        = "17.5"
    # instance_class        = "db.t4g.medium"
    # aurora_instance_count = 2
    public_access = true
    database_name = "inventory"
    init_sql_file = "../sample-data-sets/postgres.sql"
  }

  # Per-database ARNs override the top-level defaults. Lists allow more than
  # one Redis Cloud subscription to consume this database and read its secret.
  mariadb_shared = {
    engine        = "mariadb"
    public_access = true
    database_name = "inventory"
    init_sql_file = "../sample-data-sets/mariadb.sql"
    redis_privatelink_arn = [
      "arn:aws:iam::111122223333:role/redis-data-pipeline",
      "arn:aws:iam::444455556666:role/redis-data-pipeline",
    ]
    redis_secrets_arn = [
      "arn:aws:iam::111122223333:role/redis-data-pipeline-secrets-role",
      "arn:aws:iam::444455556666:role/redis-data-pipeline-secrets-role",
    ]
  }

  # Private database: no direct CIDR access. Automatic init_sql_file loading is
  # skipped for private databases; use the optional bastion tooling when needed.
  postgres_private = {
    engine        = "postgres"
    public_access = false
    database_name = "inventory"
  }

  # Omitting both ARN overrides inherits the top-level principals. SQL Server's
  # initialization script creates the inventory database itself.
  sqlserver = {
    engine        = "sqlserver"
    public_access = true
    init_sql_file = "../sample-data-sets/sqlserver.sql"
  }

  # Empty lists override the top-level ARN defaults and keep both integrations
  # closed for this database.
  oracle_closed = {
    engine                = "oracle"
    public_access         = true
    init_sql_file         = "../sample-data-sets/oracle.sql"
    redis_privatelink_arn = []
    redis_secrets_arn     = []
  }

  # To allow any AWS principal to create a PrivateLink endpoint, use:
  # redis_privatelink_arn = "*"
  # Prefer scoped principal ARNs whenever possible.
}
