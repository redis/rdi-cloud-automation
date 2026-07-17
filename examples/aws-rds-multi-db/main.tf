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

locals {
  default_redis_secrets_arns = (
    var.redis_secrets_arn == null ? [] :
    can(tolist(var.redis_secrets_arn)) ? [for arn in tolist(var.redis_secrets_arn) : tostring(arn)] :
    [tostring(var.redis_secrets_arn)]
  )

  redis_secrets_arns_by_db = {
    for key, db in var.databases : key => (
      try(db.redis_secrets_arn, null) == null ? local.default_redis_secrets_arns :
      can(tolist(db.redis_secrets_arn)) ? [for arn in tolist(db.redis_secrets_arn) : tostring(arn)] :
      [tostring(db.redis_secrets_arn)]
    )
  }
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
  engine_version        = try(each.value.engine_version, null)
  port                  = try(each.value.port, null)
  instance_class        = try(each.value.instance_class, null)
  aurora_instance_count = try(each.value.aurora_instance_count, 1)
  db_password           = random_password.db[each.key].result

  network = {
    vpc_id                     = module.network.vpc_id
    public_subnet_ids          = module.network.public_subnet_ids
    database_subnet_group_name = module.network.database_subnet_group_name
  }

  # Per-DB overrides take precedence; otherwise fall back to the top-level defaults.
  redis_secrets_arn     = local.redis_secrets_arns_by_db[each.key]
  redis_privatelink_arn = try(each.value.redis_privatelink_arn, null) != null ? each.value.redis_privatelink_arn : var.redis_privatelink_arn
  public_access         = try(each.value.public_access, false)
  # Per-DB allowed_cidrs (when set) takes precedence; otherwise inherit the top-level default.
  allowed_cidrs = try(each.value.allowed_cidrs, null) != null ? each.value.allowed_cidrs : var.allowed_cidrs
  # When the bastion is enabled, its SG gets ingress on every DB's port.
  client_security_group_ids = var.bastion.enabled ? [module.bastion[0].security_group_id] : []
  database_name             = try(each.value.database_name, null)
  init_sql_file             = try(each.value.init_sql_file, null)
}

################################################################################
# Optional bastion EC2 - shared jump box with all DB clients pre-installed.
################################################################################

resource "random_password" "bastion" {
  count = var.bastion.enabled ? 1 : 0

  length  = 20
  special = false
}

module "bastion" {
  source = "../../modules/aws-rdi-bastion"
  count  = var.bastion.enabled ? 1 : 0

  identifier        = var.name
  vpc_id            = module.network.vpc_id
  public_subnet_id  = module.network.public_subnet_ids[0]
  instance_type     = var.bastion.instance_type
  ssh_password      = random_password.bastion[0].result
  allowed_ssh_cidrs = coalesce(var.bastion.allowed_ssh_cidrs, var.allowed_cidrs)
  aws_region        = var.region

  # CDC mutation scripts loaded onto the bastion. `make update-db <db>` runs
  # the file matching the DB's engine family.
  update_scripts = {
    mysql     = file("../sample-data-sets/update-mysql.sql")
    postgres  = file("../sample-data-sets/update-postgres.sql")
    sqlserver = file("../sample-data-sets/update-sqlserver.sql")
    oracle    = file("../sample-data-sets/update-oracle.sql")
  }

  # Initial dataset reset scripts. `make reset-db <db>` drops + reloads.
  # MariaDB has its own file because MariaDB 10.11 doesn't accept the
  # MySQL 8.0 `utf8mb4_0900_ai_ci` collation that mysql.sql uses.
  reset_scripts = {
    mysql     = file("../sample-data-sets/mysql.sql")
    mariadb   = file("../sample-data-sets/mariadb.sql")
    postgres  = file("../sample-data-sets/postgres.sql")
    sqlserver = file("../sample-data-sets/sqlserver.sql")
    oracle    = file("../sample-data-sets/oracle.sql")
  }
}
