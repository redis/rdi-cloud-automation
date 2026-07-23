output "vpc_endpoint_service_name" {
  value       = module.privatelink.vpc_endpoint_service_name
  description = "The VPC Endpoint service name for the database, to be configured in Redis Cloud"
}

output "secret_arn" {
  value       = module.secret_manager.secret_arn
  description = "The Secret Manager secret ARN, to be configured in Redis Cloud"
}

output "database" {
  value       = local.source_db.database
  description = "The source database name"
}

output "database_engine" {
  value       = var.db_engine
  description = "The database engine being used (postgres, mysql, or sqlserver)"
}

output "database_engine_version" {
  value = (
    var.source_db_mode == "demo" && var.db_engine == "mysql" ? module.rdi_quickstart_mysql[0].engine_version :
    var.source_db_mode == "demo" && var.db_engine == "sqlserver" ? module.rdi_quickstart_sqlserver[0].engine_version :
    null
  )
  description = "The database engine version (demo MySQL and SQL Server only, shows latest version)"
}

output "database_username" {
  value       = local.source_db.username
  description = "The database username"
}

output "port" {
  value       = var.port
  description = "The port for the NLB"
}

output "password" {
  value       = var.source_db_mode == "demo" ? random_password.db_password.result : null
  sensitive   = true
  description = "The generated demo database password. Null for source_db_mode = 'existing'."
}

output "db_host" {
  value       = module.privatelink.lb_hostname
  description = "The hostname for connecting to the database"
}

output "rdi_username" {
  value       = local.rdi_username
  description = "The username for RDI/CDC connection (MySQL: debezium, PostgreSQL: postgres, SQL Server: rdi_user)"
}

output "rdi_password" {
  value       = local.rdi_password
  sensitive   = true
  description = "The password for RDI/CDC connection"
}

output "rds_proxy_enabled" {
  value       = var.use_rds_proxy
  description = "Whether RDS Proxy is enabled (DEPRECATED feature)"
}

output "rds_proxy_require_tls" {
  value       = var.use_rds_proxy ? var.rds_proxy_require_tls : null
  description = "Whether RDS Proxy requires TLS (only if RDS Proxy is enabled)"
}

output "rds_proxy_endpoint" {
  value       = var.use_rds_proxy ? aws_db_proxy.rds_proxy[0].endpoint : null
  description = "The RDS Proxy endpoint (only if RDS Proxy is enabled)"
}

output "rds_ca_cert_secret_arn" {
  value       = var.use_rds_proxy && var.rds_proxy_require_tls ? aws_secretsmanager_secret.rds_ca_cert[0].arn : null
  description = "The ARN of the AWS Secret containing the RDS CA certificate bundle (only if RDS Proxy with TLS is enabled)"
}

output "actual_db_endpoint" {
  value       = local.db_endpoint
  description = "The actual database endpoint being used (RDS Proxy if enabled, otherwise direct RDS endpoint)"
}

output "source_db_mode" {
  value       = var.source_db_mode
  description = "Whether the deployment is using a generated demo database or an existing database"
}

output "lambda_role_mode" {
  value       = var.lambda_role_mode
  description = "Whether Terraform created the failover Lambda execution role or used an existing role"
}

output "existing_lambda_execution_role_arn" {
  value       = var.lambda_role_mode == "existing" ? var.existing_lambda_execution_role_arn : null
  description = "The existing Lambda execution role ARN used when lambda_role_mode = 'existing'"
}

output "kms_key_mode" {
  value       = var.kms_key_mode
  description = "Whether Terraform created the Secrets Manager KMS key or used an existing key"
}

output "kms_key_arn" {
  value       = module.secret_manager.kms_key_arn
  description = "The KMS key ARN used by Secrets Manager for the RDI secret"
}

output "nlb_internal" {
  value       = var.nlb_internal
  description = "Whether the NLB is internal (private) or internet-facing (public)"
}

output "nlb_dns_name" {
  value       = module.privatelink.lb_hostname
  description = "The DNS name of the NLB (use this to connect directly when nlb_internal=false)"
}

output "rds_direct_endpoint" {
  value       = local.source_db.endpoint
  description = "The direct source database endpoint"
}

output "existing_db_nlb_security_group_id" {
  value       = var.source_db_mode == "existing" ? aws_security_group.existing_db_nlb[0].id : null
  description = "The generated NLB security group ID for existing database mode. Allow this SG to reach the source database when manage_existing_db_security_group_ingress is false."
}
