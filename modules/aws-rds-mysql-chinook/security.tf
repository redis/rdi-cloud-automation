# Creating the security group for the producer instance
resource "aws_security_group" "producer_sg" {
  vpc_id = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # To be able to connect to MySQL from the LB 
  ingress {
    from_port = var.db_port
    to_port   = var.db_port
    protocol  = "tcp"
    self      = true
  }
  # To be able to connect to MySQL from the demo machine 
  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "producer-sg-mysql-${var.identifier}"
  }
}

