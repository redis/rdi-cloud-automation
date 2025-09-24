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
