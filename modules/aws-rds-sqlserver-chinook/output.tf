output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "rds_arn" {
  value = aws_db_instance.sqlserver.arn
}

output "rds_cluster_identifier" {
  value = aws_db_instance.sqlserver.identifier
}

output "rds_endpoint" {
  value = aws_db_instance.sqlserver.endpoint
}

output "security_group_id" {
  value = aws_security_group.producer_sg.id
}

output "engine_version" {
  value       = aws_db_instance.sqlserver.engine_version
  description = "The SQL Server engine version being used"
}

