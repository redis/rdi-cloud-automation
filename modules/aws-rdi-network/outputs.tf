output "vpc_id" {
  description = "ID of the shared VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs - used by per-DB NLBs."
  value       = module.vpc.public_subnets
}

output "database_subnet_group_name" {
  description = "Shared DB subnet group - reused by every RDS resource."
  value       = module.vpc.database_subnet_group_name
}
