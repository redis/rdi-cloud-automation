# AWS RDS PrivateLink with Automatic Failover

Production-ready Terraform example to connect Redis Cloud RDI to AWS RDS databases (PostgreSQL, MySQL, or SQL Server) with automatic failover support via AWS PrivateLink. It can either create a demo database or wrap an existing customer-owned RDS/Aurora database.

## 🚀 Overview

This example deploys a complete RDS infrastructure with:
- ✅ **Multi-engine support:** PostgreSQL, MySQL, or SQL Server
- ✅ **Automatic CDC user creation:** MySQL and SQL Server users provisioned automatically
- ✅ **High availability:** Multi-AZ deployment with automatic failover
- ✅ **Lambda-based failover:** Automatically updates NLB targets during RDS failover
- ✅ **Secure connectivity:** AWS PrivateLink for private VPC-to-VPC connections
- ✅ **Optional sample data:** Chinook database (manual setup required)
- ✅ **Existing database mode:** Reuse a customer-owned RDS/Aurora database and create only the surrounding Redis Cloud access infrastructure
- ✅ **Customer-managed IAM option:** Use a pre-created Lambda execution role when the Terraform runner cannot create IAM roles

### Supported Database Engines

| Database | Engine | CDC Method | Auto User Creation | High Availability |
|----------|--------|------------|-------------------|-------------------|
| **PostgreSQL** | Aurora PostgreSQL | Logical Replication | ❌ (uses admin) | ✅ Multi-AZ |
| **MySQL** | Aurora MySQL 8.0 | Debezium (binlog) | ✅ `debezium` user | ✅ Multi-AZ |
| **SQL Server** | RDS SQL Server SE 2022 | Change Tracking | ✅ `rdi_user` | ✅ Multi-AZ |

### Architecture Reference

This implementation follows AWS best practices documented here:
https://aws.amazon.com/blogs/database/access-amazon-rds-across-vpcs-using-aws-privatelink-and-network-load-balancer/

## 📋 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) >= 1.5.7
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- [Redis Cloud](https://redis.com/try-free/) account with RDI enabled
- Database client tools (optional, for testing):
  - `psql` for PostgreSQL
  - `mysql` for MySQL
  - `sqlcmd` for SQL Server ([installation guide](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools))

### AWS Authentication

Before running `terraform plan`, `terraform apply`, or `terraform destroy`, authenticate to AWS in the same terminal session and verify the active identity:

```bash
aws sts get-caller-identity
```

If you use an AWS CLI profile, either export it before running Terraform:

```bash
export AWS_PROFILE=<profile-name>
aws sts get-caller-identity
```

or set `aws_profile` in the tfvars file:

```hcl
aws_profile = "<profile-name>"
```

If `aws_profile = null`, Terraform uses the default AWS credential chain from the terminal environment. This is useful for SSO sessions, environment credentials, or temporary credentials, but always confirm the account and role with `aws sts get-caller-identity` before applying.

## 🚦 Quick Start

1. **Initialize Terraform** (first time only):
   ```bash
   terraform init
   ```

2. **Choose your database engine** and configure the appropriate tfvars file with values from Redis Cloud RDI UI

3. **Configure** the appropriate tfvars file with values from Redis Cloud RDI UI:
   - PostgreSQL: `example-postgres.tfvars`
   - MySQL: `example-mysql.tfvars`
   - SQL Server: `example-sqlserver.tfvars`
   - Existing RDS/Aurora database: `example-existing-db.tfvars`

4. **Deploy**:
   ```bash
   # For PostgreSQL
   terraform apply -var-file example-postgres.tfvars

   # For MySQL
   terraform apply -var-file example-mysql.tfvars

   # For SQL Server
   terraform apply -var-file example-sqlserver.tfvars

   # For an existing RDS/Aurora database
   terraform apply -var-file example-existing-db.tfvars
   ```

5. **Connect** to verify (optional):
   ```bash
   ./connect.sh  # Auto-detects engine
   ```

## 📝 Configuration

### Deployment Modes

This example has three independent mode switches:

| Mode | Variable | Default | Purpose |
|------|----------|---------|---------|
| Source database | `source_db_mode` | `"demo"` | Choose whether Terraform creates a demo database or connects to an existing RDS/Aurora database |
| Lambda IAM role | `lambda_role_mode` | `"managed"` | Choose whether Terraform creates the failover Lambda execution role or uses a pre-created role |
| Secrets Manager KMS key | `kms_key_mode` | `"managed"` | Choose whether Terraform creates the KMS key for the RDI secret or uses a pre-created key |

The default path is:

```hcl
source_db_mode   = "demo"
lambda_role_mode = "managed"
kms_key_mode     = "managed"
use_rds_proxy    = false
```

For customer prototyping against an existing database, use:

```hcl
source_db_mode = "existing"
use_rds_proxy  = false
```

If the Terraform runner cannot create IAM roles, also set:

```hcl
lambda_role_mode                  = "existing"
existing_lambda_execution_role_arn = "arn:aws:iam::123456789012:role/precreated-rdi-failover-lambda-role"
```

If the Terraform runner cannot create or manage KMS keys, also set:

```hcl
kms_key_mode         = "existing"
existing_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
```

### Required Variables

All tfvars files require these values from the Redis Cloud RDI UI:

```hcl
region                = "us-east-1"
azs                   = ["use1-az2", "use1-az4", "use1-az6"]
name                  = "rdi-rds-demo"
redis_secrets_arn     = "arn:aws:iam::YOUR_ACCOUNT:role/YOUR_ROLE"
redis_privatelink_arn = "arn:aws:iam::YOUR_ACCOUNT:role/YOUR_ROLE"
```

Set `source_db_mode = "demo"` to create a sample database, or `source_db_mode = "existing"` to reuse a customer-owned RDS/Aurora database.

### Existing Database Configuration

Use `example-existing-db.tfvars` when the source database and dataset already exist. The database hostname and credentials are required, and Terraform also needs the source database VPC/subnet/security group metadata so it can create the NLB and PrivateLink service in the same network.

```hcl
source_db_mode = "existing"

existing_db = {
  hostname              = "my-db.cluster-xxxxxxxxxxxx.us-east-1.rds.amazonaws.com"
  username              = "rdi_user"
  database              = "my_database"
  vpc_id                = "vpc-xxxxxxxxxxxxxxxxx"
  subnet_ids            = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
  db_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]
  rds_event_source_id   = "my-db"
  rds_event_source_type = "db-cluster"
}

existing_db_password = "..."
```

`subnet_ids` is the most deterministic option. These are the subnets where AWS creates the NLB nodes, and they must be in the same VPC as the source database.

If customers do not want to copy subnet IDs, they can use `subnet_lookup` instead. Terraform resolves one subnet per requested Availability Zone in `existing_db.vpc_id`:

```hcl
existing_db = {
  hostname              = "my-db.cluster-xxxxxxxxxxxx.us-east-1.rds.amazonaws.com"
  username              = "rdi_user"
  database              = "my_database"
  vpc_id                = "vpc-xxxxxxxxxxxxxxxxx"
  db_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]
  rds_event_source_id   = "my-db"
  rds_event_source_type = "db-cluster"

  subnet_lookup = {
    azs = ["1a", "1b"]
    tags = {
      Tier = "private"
    }
  }
}
```

The `azs` values can be full names like `us-east-1a`, short names like `a`, or region-number suffixes like `1a`. If the lookup matches zero subnets or more than one subnet in an AZ, Terraform fails and asks for more specific tags or explicit `subnet_ids`. Do not set both `subnet_ids` and `subnet_lookup`.

Use `rds_event_source_type = "db-cluster"` for Aurora clusters and `rds_event_source_type = "db-instance"` for standard RDS instances.

By default, Terraform creates a dedicated security group for the NLB but does not modify the customer database security groups. Either:

- Set `manage_existing_db_security_group_ingress = true` to let Terraform add ingress from the generated NLB security group to `existing_db.db_security_group_ids`.
- Keep it `false` and manually allow the `existing_db_nlb_security_group_id` output to connect to the database port.

Existing database mode does not create database users and does not load sample data. The supplied `existing_db.username` and `existing_db_password` are stored in AWS Secrets Manager for Redis Cloud RDI.

### Engine-Specific Configuration

Each tfvars file is pre-configured for its database engine:

| Variable | PostgreSQL | MySQL | SQL Server |
|----------|-----------|-------|------------|
| `db_engine` | `"postgres"` | `"mysql"` | `"sqlserver"` |
| `port` | `5432` | `3306` | `1433` |

### Optional Configuration

#### Lambda IAM Role Modes

When `use_rds_proxy = false` (the default), Terraform creates a Lambda function that keeps the NLB target group pointed at the current RDS writer endpoint. That Lambda needs an execution role.

By default, Terraform creates the role and inline policies:

```hcl
lambda_role_mode = "managed"
```

Use this mode for internal testing, sandbox accounts, and accounts where the Terraform runner can create IAM roles and policies.

For customer accounts where IAM is centrally managed, ask the customer AWS admin to pre-create the role and pass its ARN:

```hcl
lambda_role_mode                  = "existing"
existing_lambda_execution_role_arn = "arn:aws:iam::123456789012:role/precreated-rdi-failover-lambda-role"
```

In `existing` role mode, Terraform still creates and configures the Lambda function, SNS topic, RDS event subscription, NLB, PrivateLink endpoint service, security groups, and Secrets Manager resources. It only skips creating the Lambda IAM role and role policies.

This is a bring-your-own-role mode, not a bring-your-own-Lambda-function mode. Keeping the Lambda function managed by this example preserves the known-good failover handler, environment variables, SNS wiring, and initial target registration behavior while removing the most common enterprise IAM blocker.

The pre-created Lambda execution role must trust Lambda:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

It also needs permissions equivalent to:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

The Terraform runner still needs `iam:PassRole` for the supplied role ARN because AWS requires that permission when creating or updating a Lambda function with an existing role.

##### AWS Console Shortcut

If the role is created in the AWS console:

1. Go to IAM → Roles → Create role.
2. Select **AWS service** as the trusted entity.
3. Select **Lambda** as the use case.
4. Attach the AWS managed policy `AWSLambdaVPCAccessExecutionRole`.
5. Add the ELB target group inline policy shown above.
6. Copy the created role ARN into `existing_lambda_execution_role_arn`.

`AWSLambdaVPCAccessExecutionRole` covers the CloudWatch Logs and VPC network-interface permissions. The inline ELB policy is still required because the failover Lambda registers and deregisters NLB target IPs.

##### Terraform Runner PassRole Permission

The user or role running Terraform needs permission to pass only the approved Lambda execution role. An AWS admin can grant that with a scoped policy like:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::123456789012:role/precreated-rdi-failover-lambda-role",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "lambda.amazonaws.com"
        }
      }
    }
  ]
}
```

Without this permission, `lambda_role_mode = "existing"` gets past IAM role creation but Lambda creation/update can still fail with `iam:PassRole`.

##### Testing With PowerUser Access

To prove the default failure mode, leave `lambda_role_mode` unset or set it to `managed`:

```hcl
lambda_role_mode = "managed"
```

A PowerUser-style account that cannot create IAM roles is expected to fail with `iam:CreateRole`.

To test the customer-managed role path, set:

```hcl
lambda_role_mode                   = "existing"
existing_lambda_execution_role_arn = "arn:aws:iam::123456789012:role/precreated-rdi-failover-lambda-role"
use_rds_proxy                      = false
```

Then run:

```bash
terraform plan -var-file example-existing-db.tfvars
```

The plan should no longer include:

```text
module.rds_lambda[0].aws_iam_role.lambda_execution_role[0]
module.rds_lambda[0].aws_iam_role_policy.ec2_elb_lambda_execution_role_policy[0]
module.rds_lambda[0].aws_iam_role_policy.log_group_lambda_execution_role_policy[0]
```

If `lambda_role_mode = "existing"` is set without `existing_lambda_execution_role_arn`, Terraform fails early with a validation error. If the role exists but the Terraform runner lacks `iam:PassRole`, apply is expected to fail at Lambda creation/update.

#### KMS Key Modes

The RDI database credentials are stored in AWS Secrets Manager. By default, this example creates a customer-managed KMS key for that secret:

```hcl
kms_key_mode = "managed"
```

Use this mode for sandbox accounts and accounts where the Terraform runner can create and manage KMS keys and key policies.

For customer accounts where KMS keys are centrally managed, ask the customer AWS admin to pre-create the key and pass its ARN:

```hcl
kms_key_mode         = "existing"
existing_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
```

In `existing` KMS mode, Terraform still creates the Secrets Manager secret and secret policy. It only skips creating, configuring, tagging, and deleting the KMS key. Terraform does not modify the existing key policy.

The pre-created KMS key policy must allow all required principals. At minimum, make sure it allows:

- The Terraform runner to use the key while creating and updating the secret.
- The Redis Cloud secrets role from `redis_secrets_arn` to decrypt the secret.
- The RDS Proxy role if deprecated `use_rds_proxy = true`.

A practical key policy statement for Redis Cloud secret reads looks like:

```json
{
  "Sid": "AllowRedisCloudSecretsRoleToDecryptRDISecret",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::123456789012:role/redis-data-pipeline-secrets-role"
  },
  "Action": [
    "kms:Decrypt",
    "kms:DescribeKey"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
    },
    "StringLike": {
      "kms:EncryptionContext:aws:secretsmanager:arn": "arn:aws:secretsmanager:us-east-1:123456789012:secret:rdi-rds-demo-*"
    }
  }
}
```

Adjust the region, account ID, role ARN, and secret name prefix to match the deployment. If the secret name is not known ahead of time, use a broader encryption-context pattern approved by the customer security team.

A practical key policy statement for the Terraform runner looks like:

```json
{
  "Sid": "AllowTerraformRunnerToUseKeyForSecretsManager",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::123456789012:role/customer-terraform-runner-role"
  },
  "Action": [
    "kms:DescribeKey",
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*",
    "kms:CreateGrant",
    "kms:ListGrants",
    "kms:RevokeGrant"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
    }
  }
}
```

Some organizations prefer to manage grants instead of broad key-policy statements. That is fine as long as Secrets Manager can use the key and the Redis Cloud secrets role can decrypt the secret value at runtime.

##### Testing With PowerUser Access

To prove the default failure mode, leave `kms_key_mode` unset or set it to `managed`:

```hcl
kms_key_mode = "managed"
```

A PowerUser-style account that cannot create or manage KMS keys may fail on `kms:CreateKey`, `kms:PutKeyPolicy`, `kms:TagResource`, or related KMS actions.

To test the customer-managed KMS path, set:

```hcl
kms_key_mode         = "existing"
existing_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
```

Then run:

```bash
terraform plan -var-file example-existing-db.tfvars
```

The plan should no longer include:

```text
module.secret_manager.aws_kms_key.rdi_key[0]
```

If `kms_key_mode = "existing"` is set without `existing_kms_key_arn`, Terraform fails early with a validation error. If the key policy does not trust the Terraform runner or Redis Cloud secrets role, apply or RDI secret reads can still fail with KMS access errors.

#### Public NLB Access (Testing)

By default, the NLB is **internal** (private, PrivateLink only). For testing TLS settings:

```hcl
nlb_internal = false  # Makes NLB internet-facing
```

**Use cases:**
- Testing database connectivity before configuring RDI
- Verifying TLS settings and credentials
- Direct access from your laptop

**Security note:** Use only for testing; keep private for production.

#### RDS Proxy (DEPRECATED)

⚠️ **Not recommended for new deployments**

```hcl
use_rds_proxy        = true
rds_proxy_require_tls = true  # Optional
```

**Why deprecated:**
- Adds unnecessary complexity and latency
- Direct RDS connection is more reliable
- Lambda-based failover is more efficient

For existing database mode, keep `use_rds_proxy = false` unless the source is an Aurora cluster and the RDS Proxy target can be registered by cluster identifier. Standard RDS instance targets should use the direct NLB + Lambda path.

## 🔌 Connecting to the Database

### From Your Laptop

Use the provided connection scripts:

```bash
# Auto-detect engine and connect
./connect.sh

# Engine-specific scripts
./psql.sh    # PostgreSQL only
./mysql.sh   # MySQL only
```

### Connection Details

Get connection information from Terraform outputs:

```bash
terraform output nlb_dns_name
terraform output rdi_username
terraform output rdi_password
```

### Manual Connection Examples

**PostgreSQL:**
```bash
psql -h <nlb_dns_name> -p 5432 -U postgres -d chinook
```

**MySQL:**
```bash
mysql -h <nlb_dns_name> -P 3306 -u debezium -p
```

**SQL Server:**
```bash
sqlcmd -S <nlb_dns_name>,1433 -U rdi_user -P '<password>' -d master
```

## 📊 Sample Data Setup (Optional)

The Chinook sample database setup is **commented out by default** in `db_setup.tf` because it requires network access to the private RDS instance.

### Why It's Commented Out

The `null_resource` provisioners in `db_setup.tf` need to connect to the RDS instance to load data. This requires:
- Either `nlb_internal = false` (public NLB) for direct access
- Or VPN/bastion host access to the VPC

### Setup Options

#### Option 1: Public NLB (Testing Only)

1. Set `nlb_internal = false` in your tfvars file
2. Uncomment the appropriate resource in `db_setup.tf`:
   - `null_resource.setup_chinook_postgres` for PostgreSQL
   - `null_resource.setup_chinook_mysql` for MySQL
   - `null_resource.setup_chinook_sqlserver` for SQL Server
3. Run `terraform apply -var-file example-<engine>.tfvars`

**Security note:** Only use public NLB for testing. Use private NLB for production.

#### Option 2: Manual Setup from Bastion Host

1. Deploy infrastructure with `nlb_internal = true` (default)
2. Set up a bastion host or VPN connection to the VPC
3. From the bastion host, download and load Chinook:

**PostgreSQL:**
```bash
curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/Chinook_PostgreSql.sql -o Chinook_PostgreSql.sql
psql -h <nlb_dns_name> -p 5432 -U postgres -d chinook -f Chinook_PostgreSql.sql
```

**MySQL:**
```bash
curl https://raw.githubusercontent.com/lerocha/chinook-database/master/ChinookDatabase/DataSources/Chinook_MySql.sql -o Chinook_MySql.sql
mysql -h <nlb_dns_name> -P 3306 -u admin chinook < Chinook_MySql.sql
```

**SQL Server:**
```bash
curl https://raw.githubusercontent.com/lerocha/chinook-database/master/ChinookDatabase/DataSources/Chinook_SqlServer.sql -o Chinook_SqlServer.sql
sqlcmd -S <nlb_dns_name>,1433 -U sa -P '<password>' -i Chinook_SqlServer.sql

# Enable CDC on Chinook database
sqlcmd -S <nlb_dns_name>,1433 -U sa -P '<password>' -Q "USE Chinook; EXEC sys.sp_cdc_enable_db;"
```

#### Option 3: AWS Systems Manager Session Manager

1. Launch an EC2 instance in the same VPC as RDS
2. Use AWS Systems Manager Session Manager to connect
3. Install database client tools on the EC2 instance
4. Follow the manual setup commands from Option 2

### What Gets Created

When Chinook is loaded, you get:
- **11 tables:** Album, Artist, Customer, Employee, Genre, Invoice, InvoiceLine, MediaType, Playlist, PlaylistTrack, Track
- **Sample data:** ~15,000 rows of music store data
- **Relationships:** Foreign keys between tables for testing CDC

### Alternative: Use Your Own Data

Instead of Chinook, you can load your own data:
1. Connect using the connection scripts (`./psql.sh`, `./mysql.sh`, etc.)
2. Create your own tables and insert data
3. Configure RDI to replicate your tables

## 🔐 CDC User Management

### Automatic User Creation

This example automatically creates CDC users for MySQL and SQL Server during deployment:

| Database | User | Password | Permissions |
|----------|------|----------|-------------|
| **PostgreSQL** | `postgres` (admin) | Random (output) | Full admin access |
| **MySQL** | `debezium` | Random (output) | `REPLICATION SLAVE`, `REPLICATION CLIENT`, `SELECT` on all tables |
| **SQL Server** | `rdi_user` | Random (output) | `db_owner`, `VIEW SERVER STATE`, `VIEW DATABASE STATE` |

### How It Works

**MySQL:**
```sql
CREATE USER 'debezium'@'%' IDENTIFIED BY '<random_password>';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
GRANT SELECT ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
```

**SQL Server:**
```sql
CREATE LOGIN rdi_user WITH PASSWORD = '<random_password>';
CREATE USER rdi_user FOR LOGIN rdi_user;
ALTER ROLE db_owner ADD MEMBER rdi_user;
GRANT VIEW SERVER STATE TO rdi_user;
GRANT VIEW DATABASE STATE TO rdi_user;
```

### Credentials Storage

All credentials are stored in AWS Secrets Manager and accessible via Terraform outputs:

```bash
terraform output db_username
terraform output db_password
terraform output rdi_secret_arn  # For RDI configuration
```

## 🏗️ Architecture

### Network Flow

```
Redis Cloud RDI
    ↓ (PrivateLink)
AWS PrivateLink Endpoint
    ↓
Network Load Balancer (NLB)
    ↓
RDS Database (Multi-AZ)
    ↓ (SNS Event on Failover)
Lambda Function
    ↓ (Updates NLB Target)
NLB Target Group
```

### Failover Handling

1. **RDS failover occurs** (primary instance fails)
2. **SNS event triggered** by RDS
3. **Lambda function invoked** automatically
4. **Lambda queries RDS** for new writer endpoint
5. **Lambda updates NLB** target group with new IP
6. **RDI reconnects** automatically to new primary

**Failover time:** Typically 30-60 seconds for Aurora, 60-120 seconds for SQL Server

### Security

- ✅ **Private connectivity:** All traffic over AWS PrivateLink
- ✅ **Encrypted credentials:** Stored in AWS Secrets Manager
- ✅ **IAM-based access:** Redis Cloud uses IAM roles
- ✅ **VPC isolation:** Database in private subnets
- ✅ **Security groups:** Restrict access to NLB only
- ✅ **TLS encryption:** Supported for all engines

## 🔐 IAM and Customer Account Pitfalls

Many customer AWS accounts do not allow application teams to create or manage IAM roles, even when they have broad PowerUser-style access. In that case, the default `lambda_role_mode = "managed"` path can fail on actions such as:

- `iam:CreateRole`
- `iam:PutRolePolicy`
- `iam:AttachRolePolicy`
- `iam:PassRole`

Use `lambda_role_mode = "existing"` when IAM roles must be created by a central cloud/security team. This removes the `iam:CreateRole` and role-policy creation requirements from this Terraform example, but the Terraform runner still needs `iam:PassRole` for the pre-created Lambda execution role.

Use `kms_key_mode = "existing"` when KMS keys must be created and governed by a central cloud/security team. This removes KMS key creation and key-policy management from this Terraform example, but the pre-created key policy must already allow Secrets Manager use and decrypt access for the Redis Cloud secrets role.

The Terraform runner may also need permissions for:

- ELBv2/NLB resources and target groups
- EC2 VPC security groups and security group rules
- Lambda function create/update/invoke permissions
- SNS topics, topic policies, subscriptions, and RDS event subscriptions
- Secrets Manager secrets and secret policies
- KMS key creation/use when creating managed secrets, or KMS key usage when `kms_key_mode = "existing"`
- Resource tagging APIs such as `ListTagsForResource`

If a customer cannot grant these permissions broadly, pre-create the Lambda execution role with the policy shown in [Lambda IAM Role Modes](#lambda-iam-role-modes), pre-create the KMS key with the policy shown in [KMS Key Modes](#kms-key-modes), then run the example with `lambda_role_mode = "existing"` and/or `kms_key_mode = "existing"`.

## 🗑️ Cleanup

To destroy all resources:

```bash
# For PostgreSQL
terraform destroy -var-file example-postgres.tfvars

# For MySQL
terraform destroy -var-file example-mysql.tfvars

# For SQL Server
terraform destroy -var-file example-sqlserver.tfvars
```

## 🛠️ Advanced Configuration

### RDS Proxy (DEPRECATED)

⚠️ **Not recommended for new deployments**

RDS Proxy can optionally be deployed between the NLB and RDS cluster:

```hcl
use_rds_proxy        = true
rds_proxy_require_tls = true  # Optional
```

**Why deprecated:**
- Adds unnecessary complexity and latency
- Direct RDS connection is more reliable and performant
- Lambda-based failover is more efficient

**When enabled:**
- Creates RDS Proxy in front of RDS cluster
- Lambda function is NOT created (proxy has static endpoint)
- Connection flow: Redis Cloud → PrivateLink → NLB → RDS Proxy → RDS

**TLS Configuration:**

When `rds_proxy_require_tls = true`:
- AWS Secrets Manager secret created with RDS CA certificate bundle
- Certificate stored as plain text (PEM format)
- Fetched from: `https://truststore.pki.rds.amazonaws.com/{region}/{region}-bundle.pem`
- Region-specific bundle used (stays within 64KB Secrets Manager limit)

**Recommended:** Use direct connection with Lambda-based failover (default).

### Database Engine Versions

**Aurora MySQL:**
- Automatically uses **latest stable Aurora MySQL 8.0** version in your region
- Determined at deployment time via Terraform data source
- No hardcoded versions that become unavailable
- Check version: `terraform output database_engine_version`

**Aurora PostgreSQL:**
- Uses specific version defined in module configuration
- Check version: `terraform output database_engine_version`

**SQL Server:**
- Uses **SQL Server 2022 Standard Edition**
- Latest patch level automatically applied
- Check version: `terraform output database_engine_version`

## 📦 Terraform Modules

This example uses the following reusable modules:

### Database Modules

| Module | Description | Engines |
|--------|-------------|---------|
| `aws-rds-chinook` | Aurora PostgreSQL with Chinook sample DB | PostgreSQL |
| `aws-rds-mysql-chinook` | Aurora MySQL with Chinook sample DB | MySQL 8.0 |
| `aws-rds-sqlserver-chinook` | RDS SQL Server with Chinook sample DB | SQL Server 2022 SE |

### Infrastructure Modules

| Module | Description | Purpose |
|--------|-------------|---------|
| `aws-rds-lambda` | Lambda function for failover handling | Updates NLB targets on RDS failover |
| `aws-privatelink` | NLB and PrivateLink endpoint | Secure connectivity from Redis Cloud |
| `aws-secret-manager` | Secrets Manager with IAM permissions | Stores credentials for RDI access |

### Module Architecture

The example uses a **conditional approach** where `db_engine` determines which database module to instantiate:

```hcl
module "rdi_quickstart_postgres" {
  count  = var.db_engine == "postgres" ? 1 : 0
  source = "../../modules/aws-rds-chinook"
  # ...
}

module "rdi_quickstart_mysql" {
  count  = var.db_engine == "mysql" ? 1 : 0
  source = "../../modules/aws-rds-mysql-chinook"
  # ...
}

module "rdi_quickstart_sqlserver" {
  count  = var.db_engine == "sqlserver" ? 1 : 0
  source = "../../modules/aws-rds-sqlserver-chinook"
  # ...
}
```

This design is **scalable** for future database engines and keeps the codebase clean.

### What's Automatic vs Manual

**Automatic (during `terraform apply`):**
- ✅ VPC, subnets, security groups
- ✅ RDS database cluster/instance
- ✅ Network Load Balancer (NLB)
- ✅ AWS PrivateLink endpoint
- ✅ Lambda function for failover handling
- ✅ AWS Secrets Manager secrets
- ✅ CDC user creation (MySQL `debezium`, SQL Server `rdi_user`)

**Manual (requires network access):**
- ⚠️ Chinook sample database loading (see "Sample Data Setup" section)
- ⚠️ Custom database/table creation
- ⚠️ Data loading for testing

**Why manual?** The Terraform execution environment typically doesn't have network access to the private RDS instance. Sample data loading requires either a public NLB (testing only), VPN connection, or bastion host.

## 🧪 Testing

See [TESTING.md](TESTING.md) for detailed testing instructions including:
- PostgreSQL testing with Chinook database
- MySQL testing with Debezium CDC
- SQL Server testing with Change Tracking
- Failover testing scenarios
- Switching between database engines

## 🐛 Troubleshooting

### Connection Issues

**Problem:** Cannot connect to database from laptop

**Solution:**
1. Check NLB is public: `nlb_internal = false`
2. Verify security group allows your IP
3. Get NLB DNS: `terraform output nlb_dns_name`
4. Test connectivity: `telnet <nlb_dns> <port>`

### CDC User Creation Issues

**Problem:** MySQL debezium user not created

**Solution:**
1. Check Terraform output for errors: `terraform output`
2. Verify RDS is accessible from Terraform execution environment
3. Check security group allows connection from Terraform host
4. Re-run: `terraform apply -var-file example-mysql.tfvars`

**Problem:** SQL Server rdi_user not created

**Solution:**
1. Verify SQL Server is in `available` state
2. Check connection string in Terraform output
3. Ensure security group allows connection
4. Re-run: `terraform apply -var-file example-sqlserver.tfvars`

### Failover Issues

**Problem:** RDI loses connection after RDS failover

**Solution:**
1. Check Lambda function logs: AWS Console → Lambda → `rds-failover-handler`
2. Verify SNS topic subscription: AWS Console → SNS
3. Check NLB target health: AWS Console → EC2 → Target Groups
4. Verify Lambda has permissions to update NLB

**Problem:** Lambda function not triggered on failover

**Solution:**
1. Verify RDS event subscription exists: `terraform output`
2. Check SNS topic has Lambda subscription
3. Test manually: Force RDS failover in AWS Console
4. Check CloudWatch Logs for Lambda execution

## 📚 Additional Resources

- [AWS RDS Multi-AZ Deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [AWS PrivateLink Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/)
- [Redis Data Integration (RDI) Documentation](https://redis.io/docs/latest/integrate/redis-data-integration/)
- [Debezium MySQL Connector](https://debezium.io/documentation/reference/stable/connectors/mysql.html)
- [SQL Server Change Tracking](https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/about-change-tracking-sql-server)

## 🤝 Contributing

See the main [README.md](../../README.md) for contributing guidelines.
