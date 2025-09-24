# AWS RDI PrivateLink Demo

This directory contains example Terraform to connect Redis Cloud RDI to an example Postgres source database.

## Usage

You can run `terraform init && terraform apply` to create the example in the `us-east-1` region.

To run in a different region you can edit `main.tf` 

## Submodules

There are 3 submodules which can be reused:

- `aws-rdi-quickstart-postgres` - creates a VPC, Security Group and EC2 instance running a demo Postgres database
- `aws-privatelink` - creates a Network Load Balancer and PrivateLink Service Endpoint to permit connectivity from Redis Cloud to the database
- `aws-secret-manager` - creates a Secret Manager secret with IAM permissions to work with Redis Cloud
