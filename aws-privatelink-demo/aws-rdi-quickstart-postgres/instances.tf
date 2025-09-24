# Simulating the relational postgresql database of the producer side
module "aws_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name = "producer-instance-${var.identifier}"

  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = var.instance_type
  subnet_id              = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids = [aws_security_group.producer_sg.id]

  # Oracle database requires a minimum of 30GB
  root_block_device = [
    {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
    }
  ]

  key_name  = var.ssh_key_name
  user_data = local.user_data
  tags = {
    Name = "producer-ec2-${var.identifier}"
  }
}
