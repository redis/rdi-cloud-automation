# AWS RDS PrivateLink with Automatic Failover

Production-ready Terraform example to connect Redis Cloud RDI to AWS RDS databases (PostgreSQL, MySQL, or SQL Server) with automatic failover support via AWS PrivateLink.

## 🚀 Overview

This example deploys a complete RDS infrastructure with:
- ✅ **Multi-engine support:** PostgreSQL, MySQL, or SQL Server
- ✅ **Automatic CDC user creation:** MySQL and SQL Server users provisioned automatically
- ✅ **High availability:** Multi-AZ deployment with automatic failover
- ✅ **Lambda-based failover:** Automatically updates NLB targets during RDS failover
- ✅ **Secure connectivity:** AWS PrivateLink for private VPC-to-VPC connections
- ✅ **Optional sample data:** Chinook database for testing

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

4. **Deploy**:
   ```bash
   # For PostgreSQL
   terraform apply -var-file example-postgres.tfvars

   # For MySQL
   terraform apply -var-file example-mysql.tfvars

   # For SQL Server
   terraform apply -var-file example-sqlserver.tfvars
   ```

5. **Connect** to verify (optional):
   ```bash
   ./connect.sh  # Auto-detects engine
   ```

## 📝 Configuration

### Required Variables

All tfvars files require these values from the Redis Cloud RDI UI:

```hcl
region                = "us-east-1"
azs                   = ["use1-az2", "use1-az4", "use1-az6"]
name                  = "rdi-rds-demo"
redis_secrets_arn     = "arn:aws:iam::YOUR_ACCOUNT:role/YOUR_ROLE"
redis_privatelink_arn = "arn:aws:iam::YOUR_ACCOUNT:role/YOUR_ROLE"
```

### Engine-Specific Configuration

Each tfvars file is pre-configured for its database engine:

| Variable | PostgreSQL | MySQL | SQL Server |
|----------|-----------|-------|------------|
| `db_engine` | `"postgres"` | `"mysql"` | `"sqlserver"` |
| `port` | `5432` | `3306` | `1433` |

### Optional Configuration

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
terraform output db_username
terraform output db_password
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
