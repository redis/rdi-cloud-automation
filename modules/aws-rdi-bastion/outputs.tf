output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP for SSH."
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "Public DNS name for SSH."
  value       = aws_instance.this.public_dns
}

output "security_group_id" {
  description = "SG ID. Pass into each DB module so the bastion can reach the DBs on their listener ports."
  value       = aws_security_group.this.id
}

output "ssh_user" {
  description = "Shared SSH user name."
  value       = "dev"
}
