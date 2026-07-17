# How to use the multi-db example

## Prerequisites

- Terraform 1.5.7 or newer.
- AWS credentials with permission to create the resources in this example.
- `jq` for the output commands below.
- When provisioning public databases from your machine, install the client for
  each selected engine: `mysql`, `psql`, `sqlcmd`, or `sqlplus`. The optional
  bastion installs all four clients automatically.

## Getting started

From this directory:

```bash
cp example.tfvars local.tfvars
terraform init
terraform apply -var-file=local.tfvars
```

Before applying, edit `local.tfvars` and replace the documentation-only ARNs,
CIDR, region-specific Availability Zone IDs, and any other example values. The
`local.tfvars` filename is ignored by Git.

Inspect the created connection details with:

```bash
terraform output
```

Destroy the deployment when it is no longer needed, especially if it includes
Oracle or SQL Server:

```bash
terraform destroy -var-file=local.tfvars
```

## Provisioning behavior

- For a public database, Terraform can create dedicated CDC users and load
  `init_sql_file` from the machine running `terraform apply`. The matching
  database client must be installed and the runner's egress IP must be in the
  database's `allowed_cidrs`.
- For a private database, automatic `init_sql_file` loading is skipped. When the
  bastion is enabled, the bundled reset and update scripts are installed there
  and can be run later with the commands below.
- Dedicated CDC-user creation still runs from the Terraform runner for MySQL,
  MariaDB, and SQL Server. When those databases are private, run Terraform from
  inside the VPC so the runner can reach the internal NLB.

## Using the bastion to connect to the source DB

1. SSH into the bastion
2. Run `make list` to list all the databases
3. Run `make sql-shell <db-name>` to connect to the database
4. Run `make reset-db <db-name>` to reset the database to the initial dataset
5. Run `make update-db <db-name>` to run the update script (CDC test mutations)

## Useful commands

### How to get the info for specific database

```bash
terraform output -json \
| jq '.databases.value["mysql"] + {master_password: .db_passwords.value["mysql"]}'
```

### How to get the info for the bastion

```bash
terraform output -json \
| jq '.bastion.value + {password: .bastion_password.value}'
```

### How to update a single source DB

```bash
terraform apply -target='module.db["aurora_postgres"]' -var-file=local.tfvars
```
