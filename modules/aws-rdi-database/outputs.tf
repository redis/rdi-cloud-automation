output "engine" {
  description = "Resolved engine string."
  value       = var.engine
}

output "endpoint" {
  description = "Direct RDS endpoint hostname (only reachable from inside the VPC)."
  value       = local.endpoint
}

output "port" {
  description = "Database listener port."
  value       = local.port
}

output "rdi_username" {
  description = "Username RDI uses to connect (CDC user, or master where engine has no separate CDC user)."
  value       = local.cfg.rdi_username
}

output "secret_arn" {
  description = "Secrets Manager ARN holding RDI credentials. Paste into Redis Cloud RDI config."
  value       = module.secret.secret_arn
}

output "vpc_endpoint_service_name" {
  description = "PrivateLink service name. Paste into Redis Cloud RDI config."
  value       = module.privatelink.vpc_endpoint_service_name
}

output "nlb_hostname" {
  description = "NLB DNS name. Public when public_access = true; internal otherwise."
  value       = module.privatelink.lb_hostname
}
