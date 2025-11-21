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
  description = "The name of the Postgres reference database"
}

output "port" {
  value       = var.port
  description = "The port for the NLB"
}

output "password" {
  value       = random_password.pg_password.result
  sensitive   = true
  description = "The postgres password. This is not used for RDI setup, only to connect to the DB with psql"
}

output "psql_host" {
  value = module.privatelink.lb_hostname
}
