terraform {
  required_version = ">= 1.5.7"

  backend "local" {
    path = "producer/terraform.tfstate"
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  # Configure the region for the resources
  region  = var.region
  profile = var.aws_profile
}

resource "terraform_data" "validate_demo_azs" {
  input = var.azs

  lifecycle {
    precondition {
      condition     = var.source_db_mode != "demo" || length(var.azs) > 0
      error_message = "azs must contain at least one availability zone when source_db_mode = \"demo\"."
    }
  }
}

resource "terraform_data" "validate_lambda_execution_role" {
  input = {
    lambda_role_mode                   = var.lambda_role_mode
    existing_lambda_execution_role_arn = var.existing_lambda_execution_role_arn
  }

  lifecycle {
    precondition {
      condition     = var.use_rds_proxy || var.lambda_role_mode == "managed" || try(length(trimspace(var.existing_lambda_execution_role_arn)) > 0, false)
      error_message = "existing_lambda_execution_role_arn must be set when lambda_role_mode = \"existing\"."
    }
  }
}

# Create an RDI quickstart Postgres database on Aurora
module "rdi_quickstart_postgres" {
  count  = var.source_db_mode == "demo" && var.db_engine == "postgres" ? 1 : 0
  source = "../../modules/aws-rds-chinook"

  identifier  = var.name
  db_password = random_password.db_password.result
  db_port     = var.port
  azs         = var.azs
}

# Create an RDI quickstart MySQL database on Aurora
module "rdi_quickstart_mysql" {
  count  = var.source_db_mode == "demo" && var.db_engine == "mysql" ? 1 : 0
  source = "../../modules/aws-rds-mysql-chinook"

  identifier  = var.name
  db_password = random_password.db_password.result
  db_port     = var.port
  azs         = var.azs
}

# Create an RDI quickstart SQL Server database on RDS
module "rdi_quickstart_sqlserver" {
  count  = var.source_db_mode == "demo" && var.db_engine == "sqlserver" ? 1 : 0
  source = "../../modules/aws-rds-sqlserver-chinook"

  identifier  = var.name
  db_password = random_password.db_password.result
  db_port     = var.port
  azs         = var.azs
}

locals {
  demo_db_username = {
    postgres  = "postgres"
    mysql     = "admin"
    sqlserver = "sa"
  }[var.db_engine]

  demo_rdi_username = {
    postgres  = "postgres"
    mysql     = "debezium"
    sqlserver = "rdi_user"
  }[var.db_engine]

  demo_rdi_password = {
    postgres  = random_password.db_password.result
    mysql     = random_password.debezium_password.result
    sqlserver = random_password.rdi_password.result
  }[var.db_engine]

  source_db = var.source_db_mode == "demo" ? {
    endpoint                    = var.db_engine == "postgres" ? module.rdi_quickstart_postgres[0].rds_endpoint : var.db_engine == "mysql" ? module.rdi_quickstart_mysql[0].rds_endpoint : module.rdi_quickstart_sqlserver[0].rds_endpoint
    username                    = local.demo_db_username
    password                    = random_password.db_password.result
    database                    = "chinook"
    vpc_id                      = var.db_engine == "postgres" ? module.rdi_quickstart_postgres[0].vpc_id : var.db_engine == "mysql" ? module.rdi_quickstart_mysql[0].vpc_id : module.rdi_quickstart_sqlserver[0].vpc_id
    subnet_ids                  = var.db_engine == "postgres" ? module.rdi_quickstart_postgres[0].vpc_public_subnets : var.db_engine == "mysql" ? module.rdi_quickstart_mysql[0].vpc_public_subnets : module.rdi_quickstart_sqlserver[0].vpc_public_subnets
    privatelink_security_groups = var.db_engine == "postgres" ? [module.rdi_quickstart_postgres[0].security_group_id] : var.db_engine == "mysql" ? [module.rdi_quickstart_mysql[0].security_group_id] : [module.rdi_quickstart_sqlserver[0].security_group_id]
    rds_event_source_id         = var.db_engine == "postgres" ? module.rdi_quickstart_postgres[0].rds_cluster_identifier : var.db_engine == "mysql" ? module.rdi_quickstart_mysql[0].rds_cluster_identifier : module.rdi_quickstart_sqlserver[0].rds_cluster_identifier
    rds_event_source_type       = var.db_engine == "sqlserver" ? "db-instance" : "db-cluster"
    } : {
    endpoint                    = var.existing_db.hostname
    username                    = var.existing_db.username
    password                    = var.existing_db_password
    database                    = var.existing_db.database
    vpc_id                      = var.existing_db.vpc_id
    subnet_ids                  = var.existing_db.subnet_ids
    privatelink_security_groups = [aws_security_group.existing_db_nlb[0].id]
    rds_event_source_id         = var.existing_db.rds_event_source_id
    rds_event_source_type       = var.existing_db.rds_event_source_type
  }

  rdi_username = var.source_db_mode == "demo" ? local.demo_rdi_username : local.source_db.username
  rdi_password = var.source_db_mode == "demo" ? local.demo_rdi_password : local.source_db.password

  # When RDS Proxy is enabled, use proxy endpoint; otherwise use RDS endpoint
  db_endpoint = var.use_rds_proxy ? aws_db_proxy.rds_proxy[0].endpoint : local.source_db.endpoint
}

resource "aws_security_group" "existing_db_nlb" {
  count = var.source_db_mode == "existing" ? 1 : 0

  name        = "${var.name}-nlb"
  description = "Security group for the RDI PrivateLink NLB"
  vpc_id      = var.existing_db.vpc_id

  tags = {
    Name = "${var.name}-nlb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "existing_db_nlb_direct_access" {
  for_each = var.source_db_mode == "existing" ? toset(var.nlb_ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.existing_db_nlb[0].id
  cidr_ipv4         = each.value
  from_port         = var.port
  ip_protocol       = "tcp"
  to_port           = var.port
}

resource "aws_vpc_security_group_egress_rule" "existing_db_nlb" {
  count = var.source_db_mode == "existing" ? 1 : 0

  security_group_id = aws_security_group.existing_db_nlb[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "existing_db_from_nlb" {
  for_each = var.source_db_mode == "existing" && var.manage_existing_db_security_group_ingress ? toset(var.existing_db.db_security_group_ids) : toset([])

  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.existing_db_nlb[0].id
  from_port                    = var.port
  ip_protocol                  = "tcp"
  to_port                      = var.port
}

# DEPRECATED: RDS Proxy (optional, not recommended for new deployments)
# Creates an RDS Proxy that sits between the NLB and the RDS cluster
resource "aws_db_proxy" "rds_proxy" {
  count = var.use_rds_proxy ? 1 : 0

  name = "${var.name}-proxy"

  # Engine family mapping - cleaner than nested ternaries
  engine_family = {
    postgres  = "POSTGRESQL"
    mysql     = "MYSQL"
    sqlserver = "SQLSERVER"
  }[var.db_engine]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = module.secret_manager.secret_arn
  }
  role_arn       = aws_iam_role.rds_proxy_role[0].arn
  vpc_subnet_ids = local.source_db.subnet_ids
  require_tls    = var.rds_proxy_require_tls

  # Use the same security group as RDS to allow NLB health checks
  # The RDS security group has a "self" ingress rule that allows traffic from resources in the same SG
  vpc_security_group_ids = local.source_db.privatelink_security_groups

  tags = {
    Name       = "${var.name}-proxy"
    Deprecated = "true"
  }

  # Only wait for secret_manager - the cluster identifier is available immediately
  # No need to wait for the full RDS cluster/instances to be created
  depends_on = [module.secret_manager]
}

resource "aws_db_proxy_default_target_group" "rds_proxy_tg" {
  count = var.use_rds_proxy ? 1 : 0

  db_proxy_name = aws_db_proxy.rds_proxy[0].name

  connection_pool_config {
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "rds_proxy_target" {
  count = var.use_rds_proxy ? 1 : 0

  db_proxy_name         = aws_db_proxy.rds_proxy[0].name
  target_group_name     = aws_db_proxy_default_target_group.rds_proxy_tg[0].name
  db_cluster_identifier = local.source_db.rds_event_source_id
}

# IAM role for RDS Proxy
resource "aws_iam_role" "rds_proxy_role" {
  count = var.use_rds_proxy ? 1 : 0

  name = "${var.name}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_proxy_policy" {
  count = var.use_rds_proxy ? 1 : 0

  name = "${var.name}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = module.secret_manager.secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = module.secret_manager.kms_key_arn
      }
    ]
  })
}

# Lambda function for RDS failover handling
# Only needed when NOT using RDS Proxy (proxy has static endpoint, no failover updates needed)
module "rds_lambda" {
  count      = var.use_rds_proxy ? 0 : 1
  source     = "../../modules/aws-rds-lambda"
  depends_on = [module.rdi_quickstart_postgres, module.rdi_quickstart_mysql, module.rdi_quickstart_sqlserver]

  identifier                = var.name
  elb_tg_arn                = module.privatelink.tg_arn
  db_endpoint               = local.db_endpoint # Direct RDS endpoint (proxy not used)
  rds_event_source_type     = local.source_db.rds_event_source_type
  rds_cluster_identifier    = local.source_db.rds_event_source_id
  db_port                   = var.port
  lambda_role_mode          = var.lambda_role_mode
  lambda_execution_role_arn = var.existing_lambda_execution_role_arn
}

# Create an NLB and PrivateLink Endpoint Service which allows secure connection to the database from Redis Cloud.
# When using RDS Proxy: NLB has static targets (no Lambda needed)
# When NOT using RDS Proxy: NLB starts with no targets, Lambda updates them dynamically
# NLB can be internal (private, default) or internet-facing (public) for testing
module "privatelink" {
  source = "../../modules/aws-privatelink"

  identifier         = var.name
  port               = var.port
  vpc_id             = local.source_db.vpc_id
  subnets            = local.source_db.subnet_ids
  target_type        = "ip"
  targets            = {} # Always start empty; Lambda will populate if not using proxy
  security_groups    = local.source_db.privatelink_security_groups
  allowed_principals = [var.redis_privatelink_arn]
  internal           = var.nlb_internal
}

# When using RDS Proxy, manually register proxy IPs to NLB target group
# This replaces the Lambda function since proxy endpoint is static
resource "null_resource" "register_proxy_targets" {
  count = var.use_rds_proxy ? 1 : 0

  depends_on = [aws_db_proxy.rds_proxy, module.privatelink]

  provisioner "local-exec" {
    command = <<EOF
#!/bin/bash
set -e

# Resolve RDS Proxy endpoint to IP addresses
PROXY_ENDPOINT="${aws_db_proxy.rds_proxy[0].endpoint}"
PROXY_IPS=$(dig +short $PROXY_ENDPOINT | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

# Register each IP to the NLB target group
for IP in $PROXY_IPS; do
  echo "Registering proxy IP $IP to NLB target group"
  aws elbv2 register-targets \
    --target-group-arn ${module.privatelink.tg_arn} \
    --targets Id=$IP,Port=${var.port} \
    --region ${var.region} \
    ${var.aws_profile != null ? "--profile ${var.aws_profile}" : ""}
done

echo "Successfully registered proxy IPs to NLB"
EOF
  }

  triggers = {
    proxy_endpoint = var.use_rds_proxy ? aws_db_proxy.rds_proxy[0].endpoint : ""
    tg_arn         = module.privatelink.tg_arn
  }
}

# Create the debezium user in MySQL with CDC permissions
# This runs after both the MySQL cluster and NLB are ready
resource "null_resource" "create_mysql_debezium_user" {
  count = var.source_db_mode == "demo" && var.db_engine == "mysql" ? 1 : 0

  depends_on = [
    module.rdi_quickstart_mysql,
    module.privatelink
  ]

  provisioner "local-exec" {
    environment = {
      MYSQL_PWD = nonsensitive(random_password.db_password.result)
    }
    command = <<EOF
#!/bin/bash
set -e

# Wait for MySQL to be fully ready (sometimes takes a moment after instance is available)
echo "Waiting for MySQL cluster to be ready..."
sleep 30

# Create debezium user with CDC permissions
echo "Creating debezium user with CDC permissions..."
mysql -h ${module.privatelink.lb_hostname} -u admin -P ${var.port} <<SQL
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY '${random_password.debezium_password.result}';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT, LOCK TABLES ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
SELECT User, Host FROM mysql.user WHERE User = 'debezium';
SQL

echo "Debezium user created successfully!"
EOF
  }

  # Recreate if any of these change
  triggers = {
    cluster_endpoint  = var.db_engine == "mysql" ? module.rdi_quickstart_mysql[0].rds_endpoint : ""
    debezium_password = random_password.debezium_password.result
    nlb_hostname      = module.privatelink.lb_hostname
  }
}

# Create the rdi_user in SQL Server with CDC permissions
# This runs after both the SQL Server instance and NLB are ready
resource "null_resource" "create_sqlserver_rdi_user" {
  count = var.source_db_mode == "demo" && var.db_engine == "sqlserver" ? 1 : 0

  depends_on = [
    module.rdi_quickstart_sqlserver,
    module.privatelink
  ]

  provisioner "local-exec" {
    command = <<EOF
#!/bin/bash
set -e

# Wait for SQL Server to be fully ready
echo "Waiting for SQL Server instance to be ready..."
sleep 60

# Create rdi_user with CDC permissions
echo "Creating rdi_user with CDC permissions..."
sqlcmd -S ${module.privatelink.lb_hostname},${var.port} -U sa -P '${random_password.db_password.result}' -Q "
-- Create login and user
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'rdi_user')
BEGIN
    CREATE LOGIN rdi_user WITH PASSWORD = '${random_password.rdi_password.result}';
END

-- Create user in master database
USE master;
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rdi_user')
BEGIN
    CREATE USER rdi_user FOR LOGIN rdi_user;
END

-- Grant necessary permissions for CDC
ALTER SERVER ROLE [dbcreator] ADD MEMBER rdi_user;
GRANT VIEW SERVER STATE TO rdi_user;
GRANT VIEW ANY DEFINITION TO rdi_user;

PRINT 'RDI user created successfully!';
"

echo "RDI user created successfully!"
EOF
  }

  # Recreate if any of these change
  triggers = {
    instance_endpoint = var.db_engine == "sqlserver" ? module.rdi_quickstart_sqlserver[0].rds_endpoint : ""
    rdi_password      = random_password.rdi_password.result
    nlb_hostname      = module.privatelink.lb_hostname
  }
}

# Create a secret in AWS Secret Manager with the RDI/Debezium credentials
# Redis Cloud needs these credentials to connect via RDI for Change Data Capture
module "secret_manager" {
  source = "../../modules/aws-secret-manager"

  # Because Secret Manager secrets are soft-deleted, add a random suffix to make the name unique.
  # Otherwise running multiple apply-destroy cycles will fail because of the names conflicting.
  identifier = "${var.name}-${random_id.secret_suffix.hex}"
  allowed_principals = compact([
    var.redis_secrets_arn,
    try(aws_iam_role.rds_proxy_role[0].arn, null)
  ])
  username = local.rdi_username # RDI/CDC user for the selected source database
  password = local.rdi_password # Corresponding password for RDI/CDC user
}

# Fetch the RDS CA certificate bundle when TLS is required
# Use region-specific bundle to stay within Secrets Manager size limits (64KB)
# The region-specific bundle is much smaller than the global bundle
data "http" "rds_ca_bundle" {
  count = var.use_rds_proxy && var.rds_proxy_require_tls ? 1 : 0
  url   = "https://truststore.pki.rds.amazonaws.com/${var.region}/${var.region}-bundle.pem"
}

# Create a secret for the RDS CA certificate bundle (only when TLS is required)
# Redis Cloud RDI needs this to verify TLS connections to RDS Proxy
resource "aws_secretsmanager_secret" "rds_ca_cert" {
  count = var.use_rds_proxy && var.rds_proxy_require_tls ? 1 : 0

  name       = "${var.name}-rds-ca-${random_id.secret_suffix.hex}"
  kms_key_id = module.secret_manager.kms_key_arn

  # Whitelist the same principals as the credentials secret (Redis Cloud)
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:PrincipalArn" : var.redis_secrets_arn
          }
        }
      }
    ]
  })
}

# Store the RDS CA certificate bundle in the secret as plain text (not JSON)
# The secret contains the PEM-encoded certificate chain
resource "aws_secretsmanager_secret_version" "rds_ca_cert" {
  count = var.use_rds_proxy && var.rds_proxy_require_tls ? 1 : 0

  secret_id     = aws_secretsmanager_secret.rds_ca_cert[0].id
  secret_string = data.http.rds_ca_bundle[0].response_body
}

resource "random_id" "secret_suffix" {
  byte_length = 8
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "random_password" "debezium_password" {
  length  = 16
  special = false
}

resource "random_password" "rdi_password" {
  length  = 16
  special = false
}
