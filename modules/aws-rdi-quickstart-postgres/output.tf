output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "instance_id" {
  value = module.aws_instance.id
}

output "ec2_public_dns" {
  value       = module.aws_instance.public_ip
  description = "The public DNS of the EC2 instance where the source database is running"
}

output "security_group_id" {
  value = aws_security_group.producer_sg.id
}

output "instance_hostname" {
  value = module.aws_instance.public_dns
}
