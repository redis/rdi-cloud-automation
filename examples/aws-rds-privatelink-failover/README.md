# AWS RDI RDS PrivateLink Demo

This directory contains example Terraform to connect Redis Cloud RDI to an Aurora Postgres RDS database and handle failover.

This blog post from AWS documents the architecture: https://aws.amazon.com/blogs/database/access-amazon-rds-across-vpcs-using-aws-privatelink-and-network-load-balancer/

## Setup

To use the example Terraform you must have:
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [AWS CLI](https://aws.amazon.com/cli/)
- [AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)

Run `terraform init` to initialize the Terraform repository. This is only necessary the first time you use the repo.

## Usage

Copy the values from the Redis Cloud RDI UI into `example.tfvars`. 

Run `terraform apply -var-file example.tfvars`

## Connecting to the database

You can connect to the postgres database directly from your laptop by running `./psql.sh`.

## Tearing down

Run `terraform destroy -var-file example.tfvars` to destroy the resources.

## Submodules

There are 4 submodules which can be reused:

- `aws-rds-chinook` - creates a VPC, Security Group and RDS database with 2 instances 
- `aws-rds-lambda` - creates a Lambda function to update the Load Balancer target group based on SNS events from RDS 
- `aws-privatelink` - creates a Network Load Balancer and PrivateLink Service Endpoint to permit connectivity from Redis Cloud to the database
- `aws-secret-manager` - creates a Secret Manager secret with IAM permissions to work with Redis Cloud
