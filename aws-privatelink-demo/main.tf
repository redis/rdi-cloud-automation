terraform {
  required_version = ">= 1.5.7"

  backend "local" {
    path = "producer/terraform.tfstate"
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  # Configure the region for the resources
  region = "us-east-1"
}

locals {
  port          = 5432
  name          = "redis-rdi"
  redis_account = "878568072780"
}

# Create an RDI quickstart Postgres database on an EC2 instance
module "rdi_quickstart_postgres" {
  source = "./aws-rdi-quickstart-postgres"

  identifier  = local.name
  db_password = random_password.pg_password.result
  db_type     = "postgresql"
  db_port     = local.port
  azs         = ["use1-az2", "use1-az4", "use1-az6"]
}

# Create an NLB and PrivateLink Endpoint Service which allows secure connection to the database from Redis Cloud
module "privatelink" {
  source = "./aws-privatelink"

  identifier         = local.name
  port               = local.port
  vpc_id             = module.rdi_quickstart_postgres.vpc_id
  subnets            = module.rdi_quickstart_postgres.vpc_public_subnets
  target_type        = "instance"
  target             = module.rdi_quickstart_postgres.instance_id
  security_groups    = [module.rdi_quickstart_postgres.security_group_id]
  allowed_principals = ["arn:aws:iam::${local.redis_account}:role/redis-data-pipeline"]
}

# Create a secret in AWS Secret Manager with the database credentials
module "secret_manager" {
  source = "./aws-secret-manager"

  # Because Secret Manager secrets are soft-deleted, add a random suffix to make the name unique.
  # Otherwise running multiple apply-destroy cycles will fail because of the names conflicting.
  identifier    = "${local.name}-${random_id.secret_suffix.hex}"
  redis_account = local.redis_account
  username      = "postgres"
  password      = random_password.pg_password.result
}

resource "random_id" "secret_suffix" {
  byte_length = 8
}

resource "random_password" "pg_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
