output "vpc_endpoint_service_name" {
  description = "PrivateLink endpoint service name to configure in Redis Cloud RDI."
  value       = module.privatelink.vpc_endpoint_service_name
}

output "vpc_endpoint_service_id" {
  description = "AWS VPC endpoint service ID."
  value       = module.privatelink.vpc_endpoint_service_id
}

output "vpc_endpoint_service_name_tag" {
  description = "Name tag on the VPC endpoint service, useful when searching in the AWS console."
  value       = module.privatelink.vpc_endpoint_service_name_tag
}

output "secret_arn" {
  description = "Secrets Manager secret ARN to configure in Redis Cloud RDI."
  value       = local.secret_arn
}

output "nlb_hostname" {
  description = "NLB DNS name created for the existing source database."
  value       = module.privatelink.lb_hostname
}

output "target_group_arn" {
  description = "Target group ARN used by the NLB. RDS/Aurora failover Lambda updates this target group when enabled."
  value       = module.privatelink.tg_arn
}

output "nlb_security_group_id" {
  description = "Security group attached to the NLB."
  value       = aws_security_group.nlb.id
}

output "target_registration_mode" {
  description = "How database targets are registered behind the NLB."
  value       = var.enable_rds_failover_lambda ? "rds-failover-lambda" : "static-targets"
}

output "resolved_db_endpoint" {
  description = "Database endpoint used by the failover Lambda, when enabled."
  value       = local.resolved_db_endpoint
}

output "rdi_configuration" {
  description = "Summary of the values normally needed when creating the RDI source connection."
  value = {
    private_link_service_name = module.privatelink.vpc_endpoint_service_name
    secret_arn                = local.secret_arn
    database_endpoint         = local.resolved_db_endpoint
    database_port             = var.db_port
    target_registration_mode  = var.enable_rds_failover_lambda ? "rds-failover-lambda" : "static-targets"
  }
}
