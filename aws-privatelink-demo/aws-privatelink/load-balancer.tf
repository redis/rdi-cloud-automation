# Create a Network Load Balancer to route traffic to the EC2 instance
resource "aws_lb" "producer_nlb" {
  name                             = "producer-nlb-${var.identifier}"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = var.subnets
  dns_record_client_routing_policy = "availability_zone_affinity"
  enable_cross_zone_load_balancing = true
  security_groups                  = var.security_groups

  tags = {
    Name = "producer-nlb-${var.identifier}"
  }
}

# Create a listener for the Network Load Balancer
resource "aws_lb_listener" "producer_listener" {
  load_balancer_arn = aws_lb.producer_nlb.arn
  port              = var.port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.producer_tg.arn
  }
}

# Create a target group for the Network Load Balancer
resource "aws_lb_target_group" "producer_tg" {
  name        = "producer-tg-${var.identifier}"
  port        = var.port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    protocol            = "TCP"
    port                = var.port
  }

  tags = {
    Name = "producer-tg-${var.identifier}"
  }
}

# Attach the EC2 instance to the target group
resource "aws_lb_target_group_attachment" "producer_tga" {
  target_group_arn = aws_lb_target_group.producer_tg.arn
  target_id        = var.target
  port             = var.port
}
