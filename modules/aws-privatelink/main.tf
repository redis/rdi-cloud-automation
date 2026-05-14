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

  provisioner "local-exec" {
    when = destroy
    environment = {
      "AWS_REGION" = split(":", self.arn)[3]
    }
    command = <<-EOF
ENDPOINT_ID="$(aws ec2 describe-vpc-endpoint-connections --query "VpcEndpointConnections[? VpcEndpointId!=null].VpcEndpointId | [0] || ''"  --filter Name=service-id,Values=${self.id} --output text)"
if [ -n "$ENDPOINT_ID" ]; then
  aws ec2 reject-vpc-endpoint-connections --service-id ${self.id} --vpc-endpoint-ids $ENDPOINT_ID
fi
EOF
  }
}
