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

# Create an RDI quickstart Postgres database on Aurora
module "rdi_quickstart_postgres" {
  count  = var.db_engine == "postgres" ? 1 : 0
  source = "../../modules/aws-rds-chinook"

  identifier  = var.name
  db_password = random_password.db_password.result
  db_port     = var.port
  azs         = var.azs
}

# Create an RDI quickstart MySQL database on Aurora
module "rdi_quickstart_mysql" {
  count  = var.db_engine == "mysql" ? 1 : 0
  source = "../../modules/aws-rds-mysql-chinook"

  identifier  = var.name
  db_password = random_password.db_password.result
  db_port     = var.port
  azs         = var.azs
}

# Create an RDI quickstart SQL Server database on RDS
module "rdi_quickstart_sqlserver" {
  count  = var.db_engine == "sqlserver" ? 1 : 0
  source = "../../modules/aws-rds-sqlserver-chinook"

  identifier  = var.name
  db_password = random_password.db_password.result
  db_port     = var.port
  azs         = var.azs
}

locals {
  # Database engine configurations - map-based approach for clarity
  # Only reference the module that actually exists (count=1) to avoid "invalid index" errors

  # Module reference - only one will exist based on db_engine
  db_module = (
    var.db_engine == "postgres" ? module.rdi_quickstart_postgres[0] :
    var.db_engine == "mysql" ? module.rdi_quickstart_mysql[0] :
    module.rdi_quickstart_sqlserver[0]
  )

  # Username mappings
  db_username = {
    postgres  = "postgres"
    mysql     = "admin"
    sqlserver = "sa"
  }[var.db_engine]

  rdi_username = {
    postgres  = "postgres"
    mysql     = "debezium"
    sqlserver = "rdi_user"
  }[var.db_engine]

  rdi_password = {
    postgres  = random_password.db_password.result
    mysql     = random_password.debezium_password.result
    sqlserver = random_password.rdi_password.result
  }[var.db_engine]

  # When RDS Proxy is enabled, use proxy endpoint; otherwise use RDS endpoint
  db_endpoint = var.use_rds_proxy ? aws_db_proxy.rds_proxy[0].endpoint : local.db_module.rds_endpoint
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
  role_arn               = aws_iam_role.rds_proxy_role[0].arn
  vpc_subnet_ids         = local.db_module.vpc_public_subnets
  require_tls            = var.rds_proxy_require_tls

  # Use the same security group as RDS to allow NLB health checks
  # The RDS security group has a "self" ingress rule that allows traffic from resources in the same SG
  vpc_security_group_ids = [local.db_module.security_group_id]

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
  db_cluster_identifier = local.db_module.rds_cluster_identifier
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
          "secretsmanager:GetSecretValue"
        ]
        Resource = module.secret_manager.secret_arn
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

  identifier             = var.name
  elb_tg_arn             = module.privatelink.tg_arn
  db_endpoint            = local.db_endpoint  # Direct RDS endpoint (proxy not used)
  rds_arn                = local.db_module.rds_arn
  rds_cluster_identifier = local.db_module.rds_cluster_identifier
  db_port                = var.port
}

# Create an NLB and PrivateLink Endpoint Service which allows secure connection to the database from Redis Cloud.
# When using RDS Proxy: NLB has static targets (no Lambda needed)
# When NOT using RDS Proxy: NLB starts with no targets, Lambda updates them dynamically
# NLB can be internal (private, default) or internet-facing (public) for testing
module "privatelink" {
  source = "../../modules/aws-privatelink"

  identifier         = var.name
  port               = var.port
  vpc_id             = local.db_module.vpc_id
  subnets            = local.db_module.vpc_public_subnets
  target_type        = "ip"
  targets            = {}  # Always start empty; Lambda will populate if not using proxy
  security_groups    = [local.db_module.security_group_id]
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
  count = var.db_engine == "mysql" ? 1 : 0

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

# Create a secret in AWS Secret Manager with the RDI/Debezium credentials
# Redis Cloud needs these credentials to connect via RDI for Change Data Capture
module "secret_manager" {
  source = "../../modules/aws-secret-manager"

  # Because Secret Manager secrets are soft-deleted, add a random suffix to make the name unique.
  # Otherwise running multiple apply-destroy cycles will fail because of the names conflicting.
  identifier         = "${var.name}-${random_id.secret_suffix.hex}"
  allowed_principals = [var.redis_secrets_arn]
  username           = local.rdi_username  # debezium for MySQL, postgres for PostgreSQL
  password           = local.rdi_password  # Corresponding password for RDI user
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
