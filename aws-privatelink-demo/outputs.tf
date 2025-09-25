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
