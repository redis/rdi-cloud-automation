terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

# Private Link Producer side = endpoint service
resource "aws_vpc_endpoint_service" "producer_service" {
  acceptance_required = var.acceptance_required
  network_load_balancer_arns = [
    aws_lb.producer_nlb.arn
  ]

  allowed_principals = var.allowed_principals

  tags = {
    Name = "producer-service-${var.identifier}"
  }
}
