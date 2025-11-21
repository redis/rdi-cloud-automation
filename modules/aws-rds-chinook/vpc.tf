module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "producer-vpc-${var.identifier}"

  cidr                    = var.vpc_cidr
  map_public_ip_on_launch = true

  azs              = local.azs
  public_subnets   = var.public_subnet_cidr
  private_subnets  = var.private_subnet_cidr
  database_subnets = var.database_subnet_cidr

  tags = {
    Name = "producer-vpc-${var.identifier}"
  }
}
