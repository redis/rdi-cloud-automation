# AWS Existing Database PrivateLink

This example creates the AWS-side infrastructure required to connect Redis Cloud RDI to an existing source database over AWS PrivateLink.

Use this when the customer already has a database such as Aurora, RDS, or a self-managed database reachable from an AWS VPC, and only needs the RDI connectivity prerequisites.

## What this creates

- Network Load Balancer (NLB)
- TCP listener and target group on the database port
- VPC Endpoint Service backed by the NLB
- Redis Cloud principal allow-listing for the endpoint service
- NLB security group
- optional database security group ingress rule
- optional Secrets Manager secret and KMS key for RDI credentials
- optional RDS/Aurora failover Lambda that keeps NLB targets synced with the current database endpoint IPs

## What this does not create

- The source database
- database schemas or sample data
- CDC parameter changes
- CDC users or grants
- Redis Cloud RDI pipeline configuration

Database-specific CDC setup must already be done, or handled manually before creating the RDI source connection.

## When to use each target mode

### RDS or Aurora

Use the default mode:

```hcl
enable_rds_failover_lambda = true
rds_source_type            = "db-cluster" # Aurora
rds_identifier             = "customer-aurora-cluster"
```

For standalone RDS instances:

```hcl
enable_rds_failover_lambda = true
rds_source_type            = "db-instance"
rds_identifier             = "customer-rds-instance"
```

RDS and Aurora expose DNS endpoints, but NLB target groups cannot directly target a DNS name. This example creates an IP target group and uses the existing `aws-rds-lambda` module to resolve the current database endpoint IPs, register them in the target group, and refresh them after RDS events such as failover, maintenance, or configuration changes.

### Static IP or EC2 instance targets

Use static targets when the source is not RDS/Aurora, or when target registration is maintained elsewhere:

```hcl
enable_rds_failover_lambda = false
target_type                = "ip"

static_targets = {
  db-1 = "10.0.101.25"
}
```

For an EC2-hosted database:

```hcl
enable_rds_failover_lambda = false
target_type                = "instance"

static_targets = {
  db-1 = "i-0123456789abcdef0"
}
```

## Prerequisites

- Terraform >= 1.5.7
- AWS CLI credentials for the customer AWS account
- existing database reachable from the supplied VPC and subnets
- Redis Cloud RDI UI values:
  - `redis_privatelink_arn`
  - `redis_secrets_arn`
- RDI database username and password, or an existing Secrets Manager secret
- database security group that allows traffic from the NLB security group, or permission for Terraform to add that ingress rule

## Configure the database first

PrivateLink is database-engine agnostic, but RDI CDC requirements are not.

Examples:

- PostgreSQL: logical replication must be enabled and the RDI user must have the required replication/read privileges.
- MySQL or MariaDB: binlog settings must be compatible with CDC, and the RDI/Debezium user must have the required replication/read privileges.
- SQL Server: change tracking or CDC setup and the RDI user permissions must be configured for the source database.
- Oracle: configure the Oracle-side RDI prerequisites separately; this example only creates the network and secret plumbing.

## Usage

Copy one of the sample tfvars files and replace every placeholder:

```bash
cp example-aurora-mysql.tfvars customer.tfvars
```

Initialize Terraform:

```bash
terraform init
```

Review the plan:

```bash
terraform plan -var-file customer.tfvars
```

Apply:

```bash
terraform apply -var-file customer.tfvars
```

After apply, copy these outputs into the Redis Cloud RDI source connection workflow:

```bash
terraform output vpc_endpoint_service_name
terraform output secret_arn
```

## Sample configurations

- `example-aurora-mysql.tfvars` - existing Aurora MySQL cluster
- `example-rds-sqlserver.tfvars` - existing standalone RDS SQL Server instance
- `example-static-targets.tfvars` - fixed IP or EC2 instance targets

## Secrets

By default, this example creates a Secrets Manager secret with placeholder values:

```hcl
create_secret = true
rdi_username  = "<put username here>"
rdi_password  = "<put password here>"
```

After `terraform apply`, open the created secret in AWS Secrets Manager and replace the placeholder JSON with the real RDI database credentials:

```json
{
  "username": "debezium",
  "password": "replace-with-the-real-password"
}
```

In the default mode, Terraform creates the initial secret value and then ignores future `secret_string` changes:

```hcl
manage_secret_value_after_creation = false
```

This lets the customer rotate or correct credentials in Secrets Manager without a later Terraform apply overwriting them with placeholders. It also keeps real database credentials out of Terraform state.

If you want Terraform to manage the secret value on every apply, opt in explicitly:

```hcl
manage_secret_value_after_creation = true
rdi_username                       = "debezium"
rdi_password                       = "replace-with-a-secure-password"
```

That mode stores the configured credential value in Terraform state.

If the customer already has a compatible secret, skip secret creation:

```hcl
create_secret        = false
existing_secret_arn  = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:rdi-source"
redis_secrets_arn    = "arn:aws:iam::123456789012:role/redis-data-pipeline-secrets-role"
```

The existing secret must be readable by the Redis Cloud secrets role from the RDI UI and should contain:

```json
{
  "username": "rdi_user",
  "password": "password"
}
```

When `create_secret = false`, this example does not update the existing secret policy or its KMS key policy. Grant `redis_secrets_arn` access to the secret before using it in the Redis Cloud RDI connection workflow.

## Security group handling

By default, Terraform creates an NLB security group but does not modify the database security group:

```hcl
manage_security_group_rule = false
```

In that mode, add an ingress rule yourself from the output `nlb_security_group_id` to the database security group on `db_port`.

If Terraform should add the rule:

```hcl
manage_security_group_rule = true
db_security_group_ids      = ["sg-0123456789abcdef0"]
```

## Existing components

This example intentionally creates a dedicated NLB, target group, and endpoint service for RDI. That keeps RDI traffic independent from application traffic and lets the failover Lambda safely manage the target group.

Customers who already have a suitable NLB or target group can still reuse the lower-level modules manually, but that is not the primary path for this example.

## Outputs

Important outputs:

- `vpc_endpoint_service_name` - configure this in Redis Cloud RDI for PrivateLink
- `secret_arn` - configure this in Redis Cloud RDI for credentials
- `target_group_arn` - useful for checking target health
- `nlb_security_group_id` - use this when manually adding database SG ingress
- `rdi_configuration` - summary of the main values

## Tear down

Before destroying this example, remove the RDI source connection or workspace that uses the PrivateLink service in Redis Cloud. AWS does not allow deleting a VPC endpoint service while it still has active consumer VPC endpoint connections.

To check whether connections still exist:

```bash
SERVICE_ID=$(terraform output -raw vpc_endpoint_service_id)

aws ec2 describe-vpc-endpoint-connections \
  --region <region> \
  --profile <aws-profile> \
  --filters Name=service-id,Values="$SERVICE_ID" \
  --query 'VpcEndpointConnections[].{EndpointId:VpcEndpointId,Owner:VpcEndpointOwner,State:VpcEndpointState}' \
  --output table
```

Continue only after the command returns no active connections, or after any remaining connections are in a deleted/rejected terminal state.

```bash
terraform destroy -var-file customer.tfvars
```

Destroy only removes resources created by this example. It does not delete or modify the source database.
