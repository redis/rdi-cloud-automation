terraform {
  required_version = ">= 1.5.7"

  backend "local" {
    path = "producer/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
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

data "aws_rds_cluster" "source" {
  count = var.enable_rds_failover_lambda && var.rds_source_type == "db-cluster" && var.rds_identifier != null ? 1 : 0

  cluster_identifier = var.rds_identifier
}

data "aws_db_instance" "source" {
  count = var.enable_rds_failover_lambda && var.rds_source_type == "db-instance" && var.rds_identifier != null ? 1 : 0

  db_instance_identifier = var.rds_identifier
}

data "aws_caller_identity" "current" {
  count = var.create_secret ? 1 : 0
}

locals {
  redis_privatelink_arns = (
    can(tolist(var.redis_privatelink_arn)) ? [for arn in tolist(var.redis_privatelink_arn) : trimspace(tostring(arn))] :
    [trimspace(tostring(var.redis_privatelink_arn))]
  )

  redis_secrets_arns = (
    can(tolist(var.redis_secrets_arn)) ? [for arn in tolist(var.redis_secrets_arn) : trimspace(tostring(arn))] :
    [trimspace(tostring(var.redis_secrets_arn))]
  )

  resolved_db_endpoint = try(coalesce(
    var.db_endpoint,
    try(data.aws_rds_cluster.source[0].endpoint, null),
    try(data.aws_db_instance.source[0].address, null),
  ), null)

  resolved_rds_source_id = try(coalesce(
    var.rds_source_id,
    var.rds_identifier,
    try(data.aws_rds_cluster.source[0].cluster_identifier, null),
  ), null)

  targets    = var.enable_rds_failover_lambda ? {} : var.static_targets
  secret_arn = var.create_secret ? aws_secretsmanager_secret.rdi[0].arn : var.existing_secret_arn
}

resource "aws_security_group" "nlb" {
  name        = "${var.name}-nlb"
  description = "RDI PrivateLink NLB for ${var.name}"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow NLB traffic to source database targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-nlb"
  })

  lifecycle {
    precondition {
      condition     = !var.enable_rds_failover_lambda || var.target_type == "ip"
      error_message = "enable_rds_failover_lambda = true requires target_type = \"ip\" because the Lambda registers resolved endpoint IP addresses."
    }

    precondition {
      condition     = !var.enable_rds_failover_lambda || local.resolved_db_endpoint != null
      error_message = "enable_rds_failover_lambda = true requires db_endpoint or an rds_identifier that can be resolved to an RDS/Aurora endpoint."
    }

    precondition {
      condition     = !var.enable_rds_failover_lambda || local.resolved_rds_source_id != null
      error_message = "enable_rds_failover_lambda = true requires rds_source_id or rds_identifier for the RDS event subscription."
    }

    precondition {
      condition     = var.enable_rds_failover_lambda || length(var.static_targets) > 0
      error_message = "When enable_rds_failover_lambda = false, static_targets must contain at least one target."
    }

    precondition {
      condition     = !var.manage_security_group_rule || length(var.db_security_group_ids) > 0
      error_message = "manage_security_group_rule = true requires at least one db_security_group_ids value."
    }

    precondition {
      condition     = var.create_secret || var.existing_secret_arn != null
      error_message = "create_secret = false requires existing_secret_arn."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_nlb" {
  for_each = var.manage_security_group_rule ? toset(var.db_security_group_ids) : []

  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.nlb.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow RDI PrivateLink NLB to reach the source database"

  tags = var.tags
}

module "privatelink" {
  source = "../../modules/aws-privatelink"

  identifier          = var.name
  port                = var.db_port
  vpc_id              = var.vpc_id
  subnets             = var.subnet_ids
  target_type         = var.target_type
  targets             = local.targets
  security_groups     = [aws_security_group.nlb.id]
  allowed_principals  = local.redis_privatelink_arns
  acceptance_required = var.acceptance_required
  internal            = var.nlb_internal
}

module "rds_failover" {
  count = var.enable_rds_failover_lambda ? 1 : 0

  source = "../../modules/aws-rds-lambda"

  identifier             = "${var.name}-targets"
  elb_tg_arn             = module.privatelink.tg_arn
  db_endpoint            = local.resolved_db_endpoint
  rds_cluster_identifier = local.resolved_rds_source_id
  rds_event_source_type  = var.rds_source_type
  db_port                = var.db_port

  depends_on = [module.privatelink]
}

resource "random_id" "secret_suffix" {
  count = var.create_secret ? 1 : 0

  byte_length = 8
}

# Secret resources are inlined instead of using modules/aws-secret-manager so
# this example can bootstrap placeholder values and then ignore future edits.
resource "aws_kms_key" "rdi_secret" {
  count = var.create_secret ? 1 : 0

  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = ""
    Statement = concat([
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current[0].account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
      ],
      [for p in local.redis_secrets_arns :
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : join(":", concat(slice(split(":", p), 0, 5), ["root"]))
          },
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : "*"
        }
    ])
  })

  tags = merge(var.tags, {
    Name = "${var.name}-rdi-secret"
  })
}

resource "aws_secretsmanager_secret" "rdi" {
  count = var.create_secret ? 1 : 0

  name       = "${var.name}-${random_id.secret_suffix[0].hex}"
  kms_key_id = aws_kms_key.rdi_secret[0].arn

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [for p in local.redis_secrets_arns :
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:PrincipalArn" : p
          }
        }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-rdi-secret"
  })
}

resource "aws_secretsmanager_secret_version" "rdi_bootstrap" {
  count = var.create_secret && !var.manage_secret_value_after_creation ? 1 : 0

  secret_id = aws_secretsmanager_secret.rdi[0].id
  secret_string = jsonencode({
    "username" : var.rdi_username,
    "password" : var.rdi_password
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret_version" "rdi_managed" {
  count = var.create_secret && var.manage_secret_value_after_creation ? 1 : 0

  secret_id = aws_secretsmanager_secret.rdi[0].id
  secret_string = jsonencode({
    "username" : var.rdi_username,
    "password" : var.rdi_password
  })
}
