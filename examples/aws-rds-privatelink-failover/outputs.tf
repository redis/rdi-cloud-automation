output "vpc_endpoint_service_name" {
  value       = module.privatelink.vpc_endpoint_service_name
  description = "The VPC Endpoint service name for the database, to be configured in Redis Cloud"
}

output "secret_arn" {
  value       = module.secret_manager.secret_arn
  description = "The Secret Manager secret ARN, to be configured in Redis Cloud"
}

output "database" {
  value       = "chinook"
  description = "The name of the reference database"
}

output "database_engine" {
  value       = var.db_engine
  description = "The database engine being used (postgres, mysql, or sqlserver)"
}

output "database_engine_version" {
  value = (
    var.db_engine == "mysql" ? module.rdi_quickstart_mysql[0].engine_version :
    var.db_engine == "sqlserver" ? module.rdi_quickstart_sqlserver[0].engine_version :
    null
  )
  description = "The database engine version (MySQL and SQL Server only, shows latest version)"
}

output "database_username" {
  value       = local.db_username
  description = "The database username"
}

output "port" {
  value       = var.port
  description = "The port for the NLB"
}

output "password" {
  value       = random_password.db_password.result
  sensitive   = true
  description = "The database password. This is not used for RDI setup, only to connect to the DB directly"
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

output "nlb_internal" {
  value       = var.nlb_internal
  description = "Whether the NLB is internal (private) or internet-facing (public)"
}

output "nlb_dns_name" {
  value       = module.privatelink.lb_hostname
  description = "The DNS name of the NLB (use this to connect directly when nlb_internal=false)"
}
