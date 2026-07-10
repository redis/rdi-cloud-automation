# Agent Guide

This repository contains Terraform automation examples and modules for Redis Cloud RDI connectivity.

The highest-priority customer path is:

> I already have an AWS RDS/Aurora PostgreSQL or MySQL database and data. How do I create the AWS infrastructure needed for Redis Cloud RDI?

For that path, start with `examples/aws-rds-privatelink-failover`.

## Where To Look First

- Customer-facing guide: `examples/aws-rds-privatelink-failover/README.md`
- Existing database inputs: `examples/aws-rds-privatelink-failover/example-existing-db.tfvars`
- Example variables: `examples/aws-rds-privatelink-failover/inputs.tf`
- Main wiring: `examples/aws-rds-privatelink-failover/main.tf`
- PrivateLink module: `modules/aws-privatelink`
- Failover Lambda module: `modules/aws-rds-lambda`
- Secrets/KMS module: `modules/aws-secret-manager`

Do not start by reading every example. Use `examples/aws-rds-privatelink-failover` unless the user explicitly asks about a different example.

## Default Recommendation For Existing Aurora PostgreSQL Or MySQL

For a customer-owned Aurora PostgreSQL source, recommend:

```hcl
source_db_mode = "existing"
db_engine      = "postgres"
port           = 5432
use_rds_proxy  = false
```

For a customer-owned Aurora MySQL source, recommend:

```hcl
source_db_mode = "existing"
db_engine      = "mysql"
port           = 3306
use_rds_proxy  = false
```

`use_rds_proxy = false` is the preferred path. RDS Proxy support is deprecated in this example.

The Terraform creates:

- Network Load Balancer
- PrivateLink endpoint service
- Failover Lambda
- SNS topic and RDS event subscription
- Secrets Manager secret for RDI credentials
- KMS key by default, or uses a customer-managed key when configured
- Security group rules when enabled

Existing database mode does not create the database, load data, create PostgreSQL users, or change database parameter groups.

## Inputs To Ask The Customer For

Ask for these values before proposing a final tfvars file:

- AWS region and, if applicable, AWS CLI profile
- Confirmation that the terminal is authenticated to the intended AWS account and role
- Redis Cloud RDI `redis_secrets_arn`
- Redis Cloud RDI `redis_privatelink_arn`
- Database hostname, for example the Aurora writer cluster endpoint
- Database port, usually `5432` for PostgreSQL or `3306` for MySQL
- Database name
- RDI database username
- RDI database password, passed as a sensitive Terraform variable when possible
- Source database VPC ID
- Subnet IDs in the same VPC as the source database, or Availability Zones plus subnet tags for `subnet_lookup`
- Source database security group IDs
- RDS event source ID, usually the Aurora cluster identifier for Aurora PostgreSQL or Aurora MySQL
- RDS event source type: `db-cluster` for Aurora, `db-instance` for standard RDS
- Whether Terraform may add DB security group ingress rules
- Whether the Terraform runner can create IAM roles
- Whether the Terraform runner can create or manage KMS keys

If the user has only PowerUser-style access, expect IAM and KMS restrictions. Suggest the pre-created role/key modes below.

## PowerUser And Enterprise Account Modes

When the Terraform runner cannot create IAM roles, use:

```hcl
lambda_role_mode                   = "existing"
existing_lambda_execution_role_arn = "arn:aws:iam::123456789012:role/precreated-rdi-failover-lambda-role"
```

The pre-created Lambda role must trust Lambda, have VPC/log permissions, and have ELB target registration permissions. The Terraform runner still needs `iam:PassRole` on that role.

When the Terraform runner cannot create or manage KMS keys, use:

```hcl
kms_key_mode         = "existing"
existing_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
```

The pre-created KMS key policy must allow Secrets Manager use and `kms:Decrypt` for the Redis Cloud secrets role from `redis_secrets_arn`. IAM permission alone may not be enough because KMS key policy is authoritative.

## Existing Database Subnet Selection

The safest input is explicit subnet IDs:

```hcl
existing_db = {
  vpc_id     = "vpc-xxxxxxxxxxxxxxxxx"
  subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
  # ...
}
```

Use this when the customer can copy subnet IDs from the AWS console or CLI.

If the customer wants a more human-readable input, use `subnet_lookup` instead:

```hcl
existing_db = {
  vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

  subnet_lookup = {
    azs = ["1a", "1b"]
    tags = {
      Tier = "private"
    }
  }

  # ...
}
```

`azs` accepts full AZ names such as `eu-north-1a`, short names such as `a`, or region-number suffixes such as `1a`. Terraform resolves the values against `region`.

Always warn that VPCs often have multiple subnets per AZ. `subnet_lookup` must match exactly one subnet per requested AZ. If it does not, ask for more specific tags or switch to explicit `subnet_ids`. Do not set both `subnet_ids` and `subnet_lookup`.

## Aurora PostgreSQL Database Prerequisites

For RDI/Debezium on PostgreSQL, remind the user to configure the database before relying on Terraform:

- Enable logical replication in the DB cluster parameter group, for example `rds.logical_replication = 1`.
- Apply the parameter group and reboot when required.
- Create an RDI/Debezium database user.
- Grant `rds_replication` to that user on AWS RDS/Aurora PostgreSQL.
- Grant `CONNECT` on the database.
- Grant `USAGE` on the schema.
- Grant `SELECT` on existing tables.
- Set default privileges for future tables.
- Create a publication, commonly `CREATE PUBLICATION dbz_publication FOR ALL TABLES;`.

Use AWS RDS/Aurora role grants such as `GRANT rds_replication TO <user>;` rather than trying to set PostgreSQL's `REPLICATION` attribute directly, which can fail on AWS managed PostgreSQL.

## Aurora MySQL Database Prerequisites

For RDI/Debezium on MySQL, remind the user to configure the database before relying on Terraform:

- Make sure binary logging is enabled and retained long enough for CDC.
- Use a binlog format compatible with Debezium/RDI, typically `ROW`.
- Create an RDI/Debezium database user.
- Grant replication permissions such as `REPLICATION SLAVE` and `REPLICATION CLIENT`.
- Grant `SELECT` on the captured schemas/tables.
- Confirm the source database security group allows traffic from the generated NLB security group or configure `manage_existing_db_security_group_ingress = true`.

For existing database mode, Terraform stores the supplied MySQL RDI username and password in Secrets Manager. It does not create the MySQL user or change MySQL parameter groups.

## Safe Command Guidance

Before suggesting Terraform commands that talk to AWS, ask the user to authenticate in the same terminal session and verify the active identity:

```bash
aws sts get-caller-identity
```

If the user relies on a named AWS CLI profile, they can either export it:

```bash
export AWS_PROFILE=<profile-name>
aws sts get-caller-identity
```

or set `aws_profile` in the tfvars file. If `aws_profile = null`, Terraform uses the default AWS credential chain from the terminal environment.

For validation:

```bash
cd examples/aws-rds-privatelink-failover
terraform init
terraform validate
terraform plan -var-file example-existing-db.tfvars
```

Do not run `terraform apply` or `terraform destroy` unless the user explicitly asks.

Prefer passing sensitive values outside committed tfvars files:

```bash
terraform apply -var-file example-existing-db.tfvars -var 'existing_db_password=...'
```

Do not commit real customer values, passwords, ARNs from private tests, VPC IDs, subnet IDs, security group IDs, account IDs, or Terraform state.

## Testing Guidance

After apply, the expected checks are:

- Terraform outputs include `vpc_endpoint_service_name` and `secret_arn` for Redis Cloud RDI.
- The Lambda exists and uses the expected execution role.
- A manual Lambda invocation with `{}` succeeds.
- The NLB target group contains the current database writer IP.
- RDI can connect through PrivateLink.
- A small insert/update/delete in the source database is observed by RDI.

For PowerUser testing:

- `lambda_role_mode = "managed"` may fail on `iam:CreateRole`; that is expected.
- `lambda_role_mode = "existing"` should not plan `aws_iam_role.lambda_execution_role`.
- Missing `existing_lambda_execution_role_arn` should fail validation.
- Missing `iam:PassRole` should fail at Lambda creation/update.
- `kms_key_mode = "managed"` may fail on KMS key creation or key policy actions.
- `kms_key_mode = "existing"` should not plan `aws_kms_key.rdi_key`.
- Missing `existing_kms_key_arn` should fail validation.

## Editing Rules For Agents

- Preserve local user edits. Do not overwrite tfvars files with real testing values.
- If committing example tfvars changes, keep customer-specific values blank or commented placeholders.
- Run `terraform fmt` on changed `.tf` files.
- Run `terraform validate` from `examples/aws-rds-privatelink-failover` when Terraform files change.
- Keep README and `example-existing-db.tfvars` aligned when adding new user-facing variables.
- For manual edits, keep changes scoped to the relevant example/module.
