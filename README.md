# rdi-cloud-automation

Terraform modules to configure producer databases and network connectivity for RDI.

## Examples

The `examples` directory contains complete examples which can be configured and run with `terraform apply`:

### aws-ec2-privatelink

Creates an example Postgres database exposed with PrivateLink. This example creates a VPC and can be used to try RDI quickly with no existing resources. 

## Modules

The `modules` directory contains reusable Terraform modules which can be composed together.

### aws-privatelink

AWS PrivateLink connection via a Network Load Balancer.

### aws-rdi-quickstart-postgres

VPC and EC2 instance with a sample Postgres database.

### aws-secret-manager

AWS KMS Key and Secret Manager secret for RDI to authenticate.
