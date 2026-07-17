################################################################################
# Per-DB PrivateLink: NLB + Endpoint Service.
# Empty target group; the failover Lambda populates targets at apply time and
# updates them on every RDS failover event.
################################################################################

module "privatelink" {
  source = "../aws-privatelink"

  identifier         = var.identifier
  port               = local.port
  vpc_id             = var.network.vpc_id
  subnets            = var.network.public_subnet_ids
  target_type        = "ip"
  targets            = {}
  security_groups    = [aws_security_group.this.id]
  allowed_principals = local.redis_privatelink_arns
  internal           = !var.public_access
}

################################################################################
# Failover Lambda: watches RDS events for this cluster/instance and keeps the
# NLB target group pointing at the current writer IP.
################################################################################

module "failover" {
  source = "../aws-rds-lambda"

  identifier             = var.identifier
  elb_tg_arn             = module.privatelink.tg_arn
  db_endpoint            = local.endpoint
  rds_arn                = local.rds_arn
  rds_cluster_identifier = local.rds_source_id
  source_type            = local.rds_source_type
  db_port                = local.port

  depends_on = [
    aws_rds_cluster_instance.this,
    aws_db_instance.this,
  ]
}

################################################################################
# Secrets Manager: RDI credentials for Redis Cloud.
# A random suffix avoids collisions across destroy/create cycles since
# Secrets Manager soft-deletes by name for 7-30 days.
################################################################################

module "secret" {
  source = "../aws-secret-manager"

  identifier         = "${var.identifier}-${random_id.secret_suffix.hex}"
  allowed_principals = local.redis_secrets_arns
  username           = local.cfg.rdi_username
  password           = local.rdi_password

  # Publish credentials only after the engine user/login has been created or
  # updated, so Secrets Manager never gets ahead of a failed password rotation.
  depends_on = [
    null_resource.create_rdi_user_mysql,
    null_resource.create_rdi_user_sqlserver,
  ]
}

resource "random_id" "secret_suffix" {
  byte_length = 8
}

resource "random_password" "rdi" {
  count = local.cfg.auto_create_rdi_user ? 1 : 0

  length  = 16
  special = false
}
