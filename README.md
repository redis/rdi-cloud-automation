# rdi-cloud-automation

[![Secret Scanning](https://github.com/redis/rdi-cloud-automation/actions/workflows/secret-scan.yml/badge.svg?branch=main)](https://github.com/redis/rdi-cloud-automation/actions/workflows/secret-scan.yml)

Terraform modules to configure producer databases and network connectivity for Redis Data Integration (RDI).

## 🚀 Overview

This repository provides production-ready Terraform modules to deploy and configure source databases for **Redis Data Integration (RDI)** with secure AWS PrivateLink connectivity. It supports multiple database engines with automatic CDC (Change Data Capture) user provisioning and optional sample data loading.

### Supported Database Engines

| Database | Engine | CDC Method | Auto User Creation | High Availability |
|----------|--------|------------|-------------------|-------------------|
| **PostgreSQL** | Aurora PostgreSQL | Logical Replication | ❌ (uses admin) | ✅ Multi-AZ |
| **MySQL** | Aurora MySQL 8.0 | Debezium (binlog) | ✅ `debezium` user | ✅ Multi-AZ |
| **SQL Server** | RDS SQL Server SE | Change Tracking | ✅ `rdi_user` | ✅ Multi-AZ |

## 📋 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) >= 1.5.7
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- [Redis Cloud](https://redis.com/try-free/) account with RDI enabled
- Database client tools (optional, for testing):
  - `psql` for PostgreSQL
  - `mysql` for MySQL
  - `sqlcmd` for SQL Server

## 📚 Examples

The `examples` directory contains complete, ready-to-deploy examples:

### aws-ec2-privatelink

Creates a PostgreSQL database on EC2 exposed with PrivateLink. This example creates a VPC and can be used to try RDI quickly with no existing resources.

**Use case:** Quick testing and development with PostgreSQL

### aws-rds-privatelink-failover

Creates production-ready RDS databases (PostgreSQL, MySQL, or SQL Server) with automatic failover support via AWS PrivateLink.

**Features:**
- ✅ **Multi-engine support:** Choose PostgreSQL, MySQL, or SQL Server
- ✅ **Automatic CDC user creation:** MySQL and SQL Server users created automatically
- ✅ **High availability:** Multi-AZ deployment with automatic failover
- ✅ **Lambda-based failover:** Automatically updates NLB targets during RDS failover
- ✅ **Optional sample data:** Chinook database for testing
- ✅ **Secure connectivity:** AWS PrivateLink for private VPC-to-VPC connections

**Quick Start:**
```bash
cd examples/aws-rds-privatelink-failover

# For PostgreSQL
terraform apply -var-file example-postgres.tfvars

# For MySQL
terraform apply -var-file example-mysql.tfvars

# For SQL Server
terraform apply -var-file example-sqlserver.tfvars
```

See [examples/aws-rds-privatelink-failover/README.md](examples/aws-rds-privatelink-failover/README.md) for detailed documentation.

## 🧩 Modules

The `modules` directory contains reusable Terraform modules which can be composed together to build custom database infrastructure.

### Database Modules

| Module | Description | Database Type | Use Case |
|--------|-------------|---------------|----------|
| **aws-rdi-quickstart-postgres** | VPC and EC2 instance with PostgreSQL | PostgreSQL on EC2 | Quick testing and development |
| **aws-rds-chinook** | Aurora PostgreSQL RDS cluster | Aurora PostgreSQL | Production PostgreSQL with HA |
| **aws-rds-mysql-chinook** | Aurora MySQL RDS cluster | Aurora MySQL 8.0 | Production MySQL with HA |
| **aws-rds-sqlserver-chinook** | RDS SQL Server instance | SQL Server SE 2022 | Production SQL Server with HA |

### Infrastructure Modules

| Module | Description | Purpose |
|--------|-------------|---------|
| **aws-privatelink** | Network Load Balancer + PrivateLink | Secure VPC-to-VPC connectivity |
| **aws-rds-lambda** | Lambda function for RDS event handling | Automatic failover detection and NLB updates |
| **aws-secret-manager** | KMS Key + Secrets Manager | Secure credential storage for RDI |

### Key Features by Module

**Database Modules:**
- ✅ VPC with public, private, and database subnets
- ✅ Security groups with self-referencing rules
- ✅ Multi-AZ deployment for high availability
- ✅ CDC-enabled parameter groups
- ✅ Automatic engine version selection (MySQL)

**aws-privatelink:**
- ✅ Network Load Balancer (internal or public)
- ✅ Cross-zone load balancing
- ✅ PrivateLink VPC Endpoint Service
- ✅ Automatic principal whitelisting

**aws-rds-lambda:**
- ✅ SNS topic for RDS events
- ✅ Lambda function to detect writer changes
- ✅ Automatic NLB target group updates
- ✅ CloudWatch logging

**aws-secret-manager:**
- ✅ KMS encryption for secrets
- ✅ IAM policy for Redis Cloud access
- ✅ Automatic credential rotation support

## 🔐 CDC User Management

The Terraform modules automatically create CDC (Change Data Capture) users with appropriate permissions for MySQL and SQL Server. PostgreSQL uses the admin user directly.

### Automatic User Creation

| Database | User | Password | Permissions | Created By |
|----------|------|----------|-------------|------------|
| **PostgreSQL** | `postgres` | Admin password | Superuser (logical replication) | RDS (admin user) |
| **MySQL** | `debezium` | Auto-generated | SELECT, RELOAD, REPLICATION SLAVE, REPLICATION CLIENT | Terraform `null_resource` |
| **SQL Server** | `rdi_user` | Auto-generated | dbcreator, VIEW SERVER STATE, VIEW ANY DEFINITION | Terraform `null_resource` |

### How It Works

**MySQL:**
```bash
# Automatically runs during terraform apply
mysql -h <nlb_hostname> -u admin -p <<SQL
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY '<auto-generated>';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT, LOCK TABLES ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
SQL
```

**SQL Server:**
```sql
-- Automatically runs during terraform apply
CREATE LOGIN rdi_user WITH PASSWORD = '<auto-generated>';
CREATE USER rdi_user FOR LOGIN rdi_user;
ALTER SERVER ROLE [dbcreator] ADD MEMBER rdi_user;
GRANT VIEW SERVER STATE TO rdi_user;
GRANT VIEW ANY DEFINITION TO rdi_user;
```

### Credentials Storage

All credentials are automatically stored in **AWS Secrets Manager** with:
- ✅ KMS encryption at rest
- ✅ IAM policy allowing Redis Cloud access
- ✅ Automatic rotation support (optional)

Access credentials via Terraform outputs:
```bash
terraform output rdi_username  # CDC username for RDI
terraform output rdi_password  # CDC password (sensitive)
terraform output secret_arn    # Secrets Manager ARN for Redis Cloud
```

## 🏗️ Architecture

### Network Flow

```
Redis Cloud RDI
    ↓
AWS PrivateLink (VPC Endpoint)
    ↓
Network Load Balancer (NLB)
    ↓
RDS Database (Multi-AZ)
```

### Failover Handling

For Aurora clusters (PostgreSQL and MySQL):
1. RDS emits failover event to SNS
2. Lambda function detects writer instance change
3. Lambda updates NLB target group with new writer IP
4. RDI connections automatically route to new writer
5. Zero configuration changes needed in Redis Cloud

### Security Architecture

- ✅ **Private connectivity:** AWS PrivateLink (no internet exposure)
- ✅ **Encryption at rest:** RDS storage encryption enabled
- ✅ **Encryption in transit:** TLS support (optional)
- ✅ **Credential management:** AWS Secrets Manager with KMS
- ✅ **Network isolation:** VPC with private subnets for databases
- ✅ **Least privilege:** IAM policies scoped to specific resources

## 💡 Common Use Cases

### 1. Quick Testing with Sample Data

Deploy PostgreSQL with Chinook sample database for immediate testing:

```bash
cd examples/aws-rds-privatelink-failover
terraform apply -var-file example-postgres.tfvars
# Chinook database is automatically created
# Connect and test: ./connect.sh
```

### 2. Production MySQL with CDC

Deploy Aurora MySQL with automatic debezium user creation:

```bash
cd examples/aws-rds-privatelink-failover
terraform apply -var-file example-mysql.tfvars
# debezium user is automatically created with CDC permissions
# Credentials stored in AWS Secrets Manager
```

### 3. SQL Server with Change Tracking

Deploy SQL Server with automatic rdi_user creation:

```bash
cd examples/aws-rds-privatelink-failover
terraform apply -var-file example-sqlserver.tfvars
# rdi_user is automatically created with CDC permissions
# Ready for SQL Server Change Tracking
```

### 4. Multi-Region Deployment

Deploy databases in multiple AWS regions for disaster recovery:

```bash
# Region 1 (us-east-1)
cd examples/aws-rds-privatelink-failover
terraform workspace new us-east-1
terraform apply -var-file example-postgres.tfvars -var region=us-east-1

# Region 2 (us-west-2)
terraform workspace new us-west-2
terraform apply -var-file example-postgres.tfvars -var region=us-west-2
```

## 🔧 Troubleshooting

### CDC User Creation Issues

**Problem:** MySQL debezium user creation fails

**Solution:**
- Ensure `mysql` client is installed locally
- Check network connectivity to NLB (set `nlb_internal = false` for testing)
- Verify admin password is correct
- Check CloudWatch logs for detailed error messages

**Problem:** SQL Server rdi_user creation fails

**Solution:**
- Ensure `sqlcmd` is installed locally ([installation guide](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools))
- Check network connectivity to NLB
- Verify sa password is correct
- SQL Server may take 60+ seconds to be ready after creation

### Connection Issues

**Problem:** Cannot connect to database from laptop

**Solution:**
- Set `nlb_internal = false` in tfvars to make NLB public
- Ensure security group allows your IP address
- Use the correct port (5432 for PostgreSQL, 3306 for MySQL, 1433 for SQL Server)
- Get connection details: `terraform output`

**Problem:** RDI cannot connect via PrivateLink

**Solution:**
- Verify PrivateLink service is whitelisted for Redis Cloud principal
- Check that the correct secret ARN is configured in Redis Cloud RDI
- Ensure the secret contains the correct username and password
- Test connectivity using `./connect.sh` script

### Failover Issues

**Problem:** Lambda not updating NLB after failover

**Solution:**
- Check Lambda CloudWatch logs for errors
- Verify SNS topic is subscribed to RDS events
- Ensure Lambda has IAM permissions to modify NLB target group
- Test failover manually: `aws rds failover-db-cluster --db-cluster-identifier <cluster-id>`

## 🔒 Security

This repository uses automated secret scanning to prevent accidental credential leaks:

- **Gitleaks** - Fast regex-based secret detection
- **TruffleHog** - High-entropy string detection with verification
- **detect-secrets** - Baseline-based secret scanning

Secret scanning runs automatically on:
- Every push to main branches
- Every pull request
- Weekly scheduled scans

For more information, see:
- [Security Policy](.github/SECURITY.md)
- [Secret Scanning Guide](.github/SECRET_SCANNING.md)

### Quick Start - Local Scanning

```bash
# Install Gitleaks
brew install gitleaks  # macOS

# Scan before committing
gitleaks detect --no-git

# Install pre-commit hook
curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/pre-commit.py -o .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Test your changes** thoroughly with `terraform plan` and `terraform apply`
3. **Run security scans** before committing:
   ```bash
   gitleaks detect --no-git
   ```
4. **Update documentation** if you add new features or modules
5. **Submit a pull request** with a clear description of changes

### Development Setup

```bash
# Clone the repository
git clone https://github.com/redis/rdi-cloud-automation.git
cd rdi-cloud-automation

# Install pre-commit hooks
curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/pre-commit.py -o .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Initialize Terraform
cd examples/aws-rds-privatelink-failover
terraform init
```

## 📄 License

This project is licensed under the terms specified in the repository.

## 🆘 Support

For issues, questions, or contributions:
- **GitHub Issues:** [Report a bug or request a feature](https://github.com/redis/rdi-cloud-automation/issues)
- **Redis Documentation:** [Redis Data Integration (RDI) Docs](https://redis.io/docs/latest/integrate/redis-data-integration/)

## 📚 Additional Resources

- [AWS PrivateLink Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/)
- [Redis Data Integration (RDI) Overview](https://redis.io/docs/latest/operate/rc/databases/rdi/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Debezium Documentation](https://debezium.io/documentation/)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
