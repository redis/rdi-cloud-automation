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
  region  = var.region
  profile = var.aws_profile
}

module "network" {
  source = "../../modules/aws-rdi-network"

  identifier = var.name
  vpc_cidr   = var.network.vpc_cidr
  azs        = var.network.azs
}

resource "random_password" "db" {
  for_each = var.databases

  length  = 16
  special = false
}

module "db" {
  source   = "../../modules/aws-rdi-database"
  for_each = var.databases

  # Prepend the deployment name so every per-DB resource is findable by
  # searching for the deployment in the AWS console.
  identifier            = "${var.name}-${each.key}"
  engine                = each.value.engine
  engine_version        = each.value.engine_version
  port                  = each.value.port
  instance_class        = each.value.instance_class
  aurora_instance_count = each.value.aurora_instance_count
  db_password    = random_password.db[each.key].result

  network = {
    vpc_id                     = module.network.vpc_id
    public_subnet_ids          = module.network.public_subnet_ids
    database_subnet_group_name = module.network.database_subnet_group_name
  }

  redis_secrets_arn     = each.value.redis_secrets_arn
  redis_privatelink_arn = each.value.redis_privatelink_arn
  public_access         = each.value.public_access
  # Per-DB allowed_cidrs (when set) takes precedence; otherwise inherit the top-level default.
  allowed_cidrs = each.value.allowed_cidrs != null ? each.value.allowed_cidrs : var.allowed_cidrs
  database_name = each.value.database_name
  init_sql_file = each.value.init_sql_file
}
