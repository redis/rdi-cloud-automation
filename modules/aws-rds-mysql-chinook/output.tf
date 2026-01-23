output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "rds_arn" {
  value = aws_rds_cluster.mysql.arn
}

output "rds_cluster_identifier" {
  value = aws_rds_cluster.mysql.cluster_identifier
}

output "rds_endpoint" {
  value = aws_rds_cluster.mysql.endpoint
}

output "security_group_id" {
  value = aws_security_group.producer_sg.id
}

output "engine_version" {
  value       = aws_rds_cluster.mysql.engine_version
  description = "The Aurora MySQL engine version being used"
}

