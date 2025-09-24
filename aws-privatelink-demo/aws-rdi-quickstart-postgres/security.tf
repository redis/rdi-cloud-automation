# Creating the security group for the producer instance
resource "aws_security_group" "producer_sg" {
  vpc_id = module.vpc.vpc_id

  # To be able to ssh in the vm
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # To be able to download/install the docker
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # To be able to ssh in the vm
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    self      = true
  }

  tags = {
    Name = "producer-sg-${var.identifier}"
  }
}
