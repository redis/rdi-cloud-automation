# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Source of truth

**Read [AGENTS.md](AGENTS.md) first.** It is the authoritative guide and covers the primary
customer path, default recommendations, required inputs, PowerUser/KMS modes, database
prerequisites, safe-command guidance, and editing rules. This file is a short orientation
layer — do not duplicate AGENTS.md content here; when the two ever disagree, AGENTS.md wins.

## What this repo is

Terraform automation examples and modules for **Redis Cloud RDI (Real-time Data Integration)**
connectivity on AWS. The highest-priority use case:

> A customer already has an AWS RDS/Aurora PostgreSQL or MySQL database and wants the AWS
> infrastructure needed for Redis Cloud RDI.

For that path, work in `examples/aws-rds-privatelink-failover`. Do not start by reading every
example — use this one unless the user explicitly asks about a different example.

## Layout

- `examples/aws-rds-privatelink-failover/` — primary example (PrivateLink + failover Lambda).
  - `README.md` — customer-facing guide
  - `TESTING.md` — validation checklist
  - `inputs.tf`, `main.tf`, `outputs.tf` — variables, wiring, outputs
  - `example-existing-db.tfvars` — inputs for an existing customer database
  - `example-postgres.tfvars` / `example-mysql.tfvars` / `example-sqlserver.tfvars` — demo DBs
- `examples/aws-ec2-privatelink/` — EC2-based PrivateLink example
- `modules/aws-privatelink` — NLB + PrivateLink endpoint service
- `modules/aws-rds-lambda` — failover Lambda, SNS topic, RDS event subscription
- `modules/aws-secret-manager` — Secrets Manager secret + KMS for RDI credentials
- `modules/aws-rdi-quickstart-postgres` — RDI quickstart for PostgreSQL
- `modules/aws-rds-*-chinook` — sample databases (postgres/mysql/sqlserver)

## Working conventions

- Run `terraform fmt` on changed `.tf` files.
- Run `terraform validate` from `examples/aws-rds-privatelink-failover` when Terraform changes.
- **Never** run `terraform apply` or `terraform destroy` unless the user explicitly asks.
- Before any AWS-touching command, have the user verify identity with `aws sts get-caller-identity`.
- Do not commit real customer values (passwords, ARNs, VPC/subnet/SG IDs, account IDs) or state.
- Keep example tfvars values blank or as commented placeholders; preserve local user edits.
- Keep changes scoped to the relevant example/module; keep README and `example-existing-db.tfvars`
  aligned when adding user-facing variables.

## Quick validation

```bash
cd examples/aws-rds-privatelink-failover
terraform init
terraform validate
terraform plan -var-file example-existing-db.tfvars
```
