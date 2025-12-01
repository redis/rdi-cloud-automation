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
  region = var.region
}

# Create an RDI quickstart Postgres database on RDS 
module "rdi_quickstart_postgres" {
  source = "../../modules/aws-rds-chinook"

  identifier  = var.name
  db_password = random_password.pg_password.result
  db_port     = var.port
  azs         = var.azs
}

module "rds_lambda" {
  source     = "../../modules/aws-rds-lambda"
  depends_on = [module.rdi_quickstart_postgres]

  identifier  = var.name
  elb_tg_arn  = module.privatelink.tg_arn
  db_endpoint = module.rdi_quickstart_postgres.rds_endpoint
  rds_arn     = module.rdi_quickstart_postgres.rds_arn
  db_port     = var.port
}

# Create an NLB and PrivateLink Endpoint Service which allows secure connection to the database from Redis Cloud.
# This has no targets but we will add a Lambda function to update the target.
module "privatelink" {
  source = "../../modules/aws-privatelink"

  identifier         = var.name
  port               = var.port
  vpc_id             = module.rdi_quickstart_postgres.vpc_id
  subnets            = module.rdi_quickstart_postgres.vpc_public_subnets
  target_type        = "ip"
  targets            = {} 
  security_groups    = [module.rdi_quickstart_postgres.security_group_id]
  allowed_principals = [var.redis_privatelink_arn]
}

# Create a secret in AWS Secret Manager with the database credentials
module "secret_manager" {
  source = "../../modules/aws-secret-manager"

  # Because Secret Manager secrets are soft-deleted, add a random suffix to make the name unique.
  # Otherwise running multiple apply-destroy cycles will fail because of the names conflicting.
  identifier         = "${var.name}-${random_id.secret_suffix.hex}"
  allowed_principals = [var.redis_secrets_arn]
  username           = "postgres"
  password           = random_password.pg_password.result
}

resource "random_id" "secret_suffix" {
  byte_length = 8
}

resource "random_password" "pg_password" {
  length  = 16
  special = false
}
