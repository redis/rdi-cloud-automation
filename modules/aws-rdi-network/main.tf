locals {
  # Translate zone IDs (euc1-az1) into zone names (eu-central-1a) for the VPC module.
  zone_map   = zipmap(data.aws_availability_zones.available.zone_ids, data.aws_availability_zones.available.names)
  zone_names = [for az_id in var.azs : local.zone_map[az_id]]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "rdi-vpc-${var.identifier}"

  cidr = var.vpc_cidr
  azs  = local.zone_names

  # Public subnets host the NLBs; private subnets exist for future workloads (bastion, lambda-in-VPC);
  # database subnets host the RDS instances. Offsets keep CIDR ranges visually distinct.
  public_subnets          = [for i in range(length(local.zone_names)) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets         = [for i in range(length(local.zone_names)) : cidrsubnet(var.vpc_cidr, 8, i + 50)]
  database_subnets        = [for i in range(length(local.zone_names)) : cidrsubnet(var.vpc_cidr, 8, i + 100)]
  map_public_ip_on_launch = true

  tags = {
    Name = "rdi-vpc-${var.identifier}"
  }
}
