# Testing Aurora MySQL Implementation

This guide will help you test the new Aurora MySQL implementation alongside the existing PostgreSQL setup.

## Quick Start

### Testing PostgreSQL (Existing)

1. Configure `example.tfvars`:
```hcl
region                = "us-east-1"
azs                   = ["use1-az2", "use1-az4", "use1-az6"]
port                  = 5432
name                  = "rdi-rds-postgres"
redis_secrets_arn     = "arn:aws:iam::YOUR_ACCOUNT:role/YOUR_ROLE"
redis_privatelink_arn = "arn:aws:iam::YOUR_ACCOUNT:role/YOUR_ROLE"
db_engine             = "postgres"
```

2. Deploy:
```bash
cd examples/aws-rds-privatelink-failover
terraform init
terraform apply -var-file example.tfvars
```

3. Connect:
```bash
./connect.sh
# or
./psql.sh
```

### Testing MySQL (New)

1. Configure `example-mysql.tfvars`:
```hcl
region                = "us-east-1"
azs                   = ["use1-az2", "use1-az4", "use1-az6"]
port                  = 3306
name                  = "rdi-rds-mysql"
redis_secrets_arn     = "arn:aws:iam::YOUR_ACCOUNT:role/YOUR_ROLE"
redis_privatelink_arn = "arn:aws:iam::YOUR_ACCOUNT:role/YOUR_ROLE"
db_engine             = "mysql"
```

2. Deploy:
```bash
cd examples/aws-rds-privatelink-failover
terraform init
terraform apply -var-file example-mysql.tfvars
```

3. Connect:
```bash
./connect.sh
# or
./mysql.sh
```

## What Was Implemented

### New Module: `aws-rds-mysql-chinook`

A new Terraform module that creates:
- Aurora MySQL 8.0 cluster with 2 instances
- VPC with public, private, and database subnets
- Security groups configured for MySQL port (3306)
- Cluster parameter group with binlog settings for CDC:
  - `binlog_format = ROW`
  - `binlog_row_image = FULL`

### Updated Example Configuration

The `examples/aws-rds-privatelink-failover` now supports both database engines:
- New variable `db_engine` to choose between "postgres" or "mysql"
- Conditional module instantiation based on engine selection
- Dynamic username selection (postgres vs admin)
- Separate setup scripts for each database type

### Connection Scripts

- `connect.sh` - Universal script that auto-detects the database engine
- `psql.sh` - PostgreSQL-specific connection
- `mysql.sh` - MySQL-specific connection

### Database Setup

The `db_setup.tf` file contains conditional resources that automatically download and load the Chinook sample database based on the selected engine:
- **PostgreSQL**: Uses the PostgreSQL version from rdi-quickstart-postgres repo
- **MySQL**: Uses the MySQL version from the chinook-database repo, and creates a dedicated `debezium` user with the required grants:
  - `SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT, LOCK TABLES`

This approach is scalable for future database engines (SQL Server, standard RDS MySQL, etc.) - each engine gets its own conditional setup resource.

## Key Differences

| Feature | PostgreSQL | MySQL |
|---------|-----------|-------|
| Default Port | 5432 | 3306 |
| Default Username | postgres | admin |
| Engine Version | aurora-postgresql17 | aurora-mysql 8.0.mysql_aurora.3.05.2 |
| CDC Configuration | logical_replication | binlog_format + binlog_row_image |
| Parameter Family | aurora-postgresql17 | aurora-mysql8.0 |

## Outputs

After deployment, you'll get:
- `vpc_endpoint_service_name` - For Redis Cloud configuration
- `secret_arn` - For Redis Cloud configuration
- `database` - Database name (chinook)
- `database_engine` - Engine type (postgres/mysql)
- `database_username` - Admin username for direct connection
- `rdi_username` - Username for RDI/Debezium connection (MySQL: `debezium`, PostgreSQL: `postgres`)
- `port` - Connection port
- `password` - Admin database password (sensitive)
- `rdi_password` - Password for RDI/Debezium connection (sensitive)
- `db_host` - Hostname for direct connection

## Troubleshooting

### MySQL Connection Issues

If you can't connect to MySQL, ensure:
1. The security group allows inbound traffic on port 3306
2. The MySQL client is installed: `brew install mysql-client` (macOS)
3. The password doesn't contain special characters that need escaping

### Terraform State

If switching between engines in the same directory:
```bash
terraform destroy -var-file example.tfvars
rm -rf .terraform terraform.tfstate*
terraform init
terraform apply -var-file example-mysql.tfvars
```

## Next Steps

1. Test the deployment with your Redis Cloud RDI instance
2. Verify CDC (Change Data Capture) is working correctly
3. Test failover scenarios with the Lambda function
4. Monitor the RDS cluster performance

