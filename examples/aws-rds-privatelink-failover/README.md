# AWS RDI RDS PrivateLink Demo

This directory contains example Terraform to connect Redis Cloud RDI to an Aurora RDS database (PostgreSQL or MySQL) and handle failover.

This blog post from AWS documents the architecture: https://aws.amazon.com/blogs/database/access-amazon-rds-across-vpcs-using-aws-privatelink-and-network-load-balancer/

## Setup

To use the example Terraform you must have:
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [AWS CLI](https://aws.amazon.com/cli/)
- [AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)

Run `terraform init` to initialize the Terraform repository. This is only necessary the first time you use the repo.

## Usage

### Configuration

1. Copy the values from the Redis Cloud RDI UI into `example.tfvars`
2. Choose your database engine by setting `db_engine` to either `"postgres"` or `"mysql"`
3. Set the appropriate port:
   - PostgreSQL: `port = 5432`
   - MySQL: `port = 3306`
4. (Optional) Make NLB public by setting `nlb_internal = false`
   - Default: `true` (private, PrivateLink only)
   - Set to `false` for direct public access (useful for testing TLS settings)
5. (Optional) Enable RDS Proxy by setting `use_rds_proxy = true`
   - **⚠️ DEPRECATED**: RDS Proxy is deprecated and not recommended for new deployments
   - Default: `false` (direct connection to RDS)

### Deployment

Run `terraform apply -var-file example.tfvars`

## Connecting to the database

You can connect to the database directly from your laptop:

- **Universal script** (auto-detects engine): `./connect.sh`
- **PostgreSQL only**: `./psql.sh`
- **MySQL only**: `./mysql.sh`

## Tearing down

Run `terraform destroy -var-file example.tfvars` to destroy the resources.

## Public NLB Access (Optional)

By default, the Network Load Balancer (NLB) is **internal** (private), meaning it's only accessible via AWS PrivateLink from Redis Cloud.

For testing purposes (e.g., testing TLS settings before configuring RDI), you can make the NLB **internet-facing** (public):

**To enable public access:**
```hcl
nlb_internal = false
```

**When enabled:**
- The NLB gets a public DNS name
- You can connect directly from your laptop using the NLB DNS name
- Useful for testing database connectivity, TLS settings, and credentials
- Still works with PrivateLink for Redis Cloud connections

**Security considerations:**
- Ensure your database security group allows inbound traffic from your IP
- Use strong passwords and TLS encryption
- Consider this for testing only; use private NLB for production

**To connect when public:**
```bash
# MySQL
mysql -h <nlb_dns_name> -P 3306 -u debezium -p

# PostgreSQL
psql -h <nlb_dns_name> -p 5432 -U postgres -d chinook
```

Get the NLB DNS name from: `terraform output nlb_dns_name`

## RDS Proxy (DEPRECATED)

⚠️ **This feature is deprecated and not recommended for new deployments.**

RDS Proxy can optionally be deployed between the Network Load Balancer and the RDS cluster. To enable it, set `use_rds_proxy = true` in your tfvars file.

**Why it's deprecated:**
- Adds unnecessary complexity and latency
- Direct RDS connection is more reliable and performant
- RDS Proxy was originally intended for connection pooling, which is not needed in this architecture

**When enabled:**
- Creates an RDS Proxy in front of the RDS cluster
- Lambda function is NOT created (proxy has static endpoint)
- Proxy IPs are manually registered to NLB target group
- Connection flow: Redis Cloud → PrivateLink → NLB → RDS Proxy → RDS Cluster

**TLS Configuration:**

By default, TLS is **not required** for RDS Proxy connections. To require TLS:

```hcl
use_rds_proxy        = true
rds_proxy_require_tls = true
```

When TLS is enabled, the following additional resources are created:
- AWS Secrets Manager secret containing the RDS CA certificate bundle (region-specific)
- The CA certificate is stored as **plain text** (PEM format), not JSON key-value pairs
- The CA certificate secret is whitelisted for Redis Cloud access (same as credentials secret)
- Redis Cloud RDI can use this certificate to verify TLS connections to RDS Proxy

The CA certificate bundle is automatically fetched from AWS's public trust store:
`https://truststore.pki.rds.amazonaws.com/{region}/{region}-bundle.pem`

**Note**: We use the region-specific bundle (not the global bundle) to stay within AWS Secrets Manager's 64KB size limit.

**Default behavior (recommended):**
- Direct connection: Redis Cloud → PrivateLink → NLB → RDS Cluster
- Lambda dynamically updates NLB targets during RDS failover

## Database Engine Versions

### Aurora MySQL
The MySQL module automatically uses the **latest stable Aurora MySQL 8.0 version** available in your region. This is determined at deployment time using a Terraform data source, ensuring:
- No hardcoded versions that become unavailable
- Always uses the most recent stable 8.0 release
- Regional availability is automatically handled

You can check which version will be deployed:
```bash
terraform output database_engine_version
```

### Aurora PostgreSQL
The PostgreSQL module uses a specific version defined in the module configuration.

## Submodules

There are 5 submodules which can be reused:

- `aws-rds-chinook` - creates a VPC, Security Group and Aurora PostgreSQL RDS database with 2 instances
- `aws-rds-mysql-chinook` - creates a VPC, Security Group and Aurora MySQL RDS database with 2 instances (auto-selects latest 8.0 version)
- `aws-rds-lambda` - creates a Lambda function to update the Load Balancer target group based on SNS events from RDS
- `aws-privatelink` - creates a Network Load Balancer and PrivateLink Service Endpoint to permit connectivity from Redis Cloud to the database
- `aws-secret-manager` - creates a Secret Manager secret with IAM permissions to work with Redis Cloud

## Architecture

The example uses a conditional approach where the `db_engine` variable determines which database module to instantiate. This design is scalable for future database engines (e.g., SQL Server, standard RDS MySQL, etc.). The `db_setup.tf` file contains separate setup resources for each database type, automatically loading the appropriate Chinook sample database.
