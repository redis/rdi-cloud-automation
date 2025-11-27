output "vpc_endpoint_service_name_tag" {
  value       = aws_vpc_endpoint_service.producer_service.tags["Name"]
  description = "The 'Name' tag of the VPC endpoint service - source Private Link service name for AWS UI search"
}

output "vpc_endpoint_service_name" {
  value       = aws_vpc_endpoint_service.producer_service.service_name
  description = "The name of the VPC endpoint service - source Private Link service name"
}

output "vpc_endpoint_service_id" {
  value       = aws_vpc_endpoint_service.producer_service.id
  description = "The ID of the VPC endpoint service - source Private Link service ID"
}

output "lb_hostname" {
  value = aws_lb.producer_nlb.dns_name
}

output "tg_arn" {
  value = aws_lb_target_group.producer_tg.arn
}
