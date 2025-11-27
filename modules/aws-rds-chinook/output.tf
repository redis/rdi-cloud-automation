output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "rds_arn" {
  value = aws_rds_cluster.postgresql.arn
}

output "rds_endpoint" {
  value = aws_rds_cluster.postgresql.endpoint
}

output "security_group_id" {
  value = aws_security_group.producer_sg.id
}
