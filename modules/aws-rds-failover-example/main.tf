# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.identifier}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_elb_lambda_execution_role_policy" {
  name = "${var.identifier}-ec2-elb-lambda-execution-role-policy"
  role = aws_iam_role.lambda_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:RegisterTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "log_group_lambda_execution_role_policy" {
  name = "${var.identifier}-log-group-lambda-execution-role-policy"
  role = aws_iam_role.lambda_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "rdi_failover_lambda" {
  filename         = data.archive_file.rdi_failover_lambda.output_path
  function_name    = "RDI-Failover-Lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda.lambda_handler"
  environment {
    variables = {
      Cluster_EndPoint = "" # TODO
      RDS_Port = "" # TODO
      NLB_TG_ARN = "" # TODO: ???
    }
  }
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 128
}

resource "aws_cloudwatch_log_group" "hello_world_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.rdi_failover_lambda.function_name}"
  retention_in_days = 14
}

# SNS Topic
resource "aws_sns_topic" "rdi_failover_topic" {
  name         = var.sns_topic_name
  display_name = "RDI Failover Topic"
}

resource "aws_sns_topic_policy" "rdi_failover_topic_policy" {
  arn = aws_sns_topic.rdi_failover_topic.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
           "SNS:GetTopicAttributes",
           "SNS:SetTopicAttributes",
           "SNS:AddPermission",
           "SNS:RemovePermission",
           "SNS:DeleteTopic",
           "SNS:Subscribe",
           "SNS:ListSubscriptionsByTopic",
           "SNS:Publish",
           "SNS:Receive"
        ]
        Resource = aws_sns_topic.rdi_failover_topic.arn
      }
    ]
  })
}


resource "aws_sns_topic_subscription" "rdi_failover_subscription" {
  topic_arn = aws_sns_topic.rdi_failover_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.rdi_failover_lambda.arn
}

resource "aws_db_event_subscription" "rds_instance_failover_event" {
  name = "${var.identifier}-rds-instance-events"
  sns_topic = aws_sns_topic.rdi_failover_topic.arn
  event_categories = ["failover", "failure"]
  source_type = "db-instance"
  enabled = true
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rdi_failover_lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.rdi_failover_topic.arn
}

# TODO: create NLB
resource "aws_lb" "rdi_failover_nlb" {
  name = "${var.identifier}-rdi-failover-nlb"
  load_balancer_type = "network"
  subnets = # TODO: add subnets
  internal = true
}

resource "aws_lb_target_group" "rdi_failover_nlb_target_group" {
  name = "${var.identifier}-rdi-failover-nlb-target-group"
  port = # TODO
  protocol = "TCP"
  target_type = "ip"
  vpc_id = # TODO
  health_check {  
    protocol = "TCP"
    port = # TODO
    interval = 10
    timeout = 10
    healthy_threshold = 3
    enabled = true
  }
}

resource "aws_lb_listener" "rdi_failover_nlb_listener" {
  load_balancer_arn = aws_lb.rdi_failover_nlb.arn
  port = # TODO
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.rdi_failover_nlb_target_group.arn
  }
}

resource "aws_vpc_endpoint_service" "rdi_failover_vpc_endpoint_service" {
  acceptance_required = false
  network_load_balancer_arns = [aws_lb.rdi_failover_nlb.arn]
}

resource "aws_vpc_endpoint_service_allowed_principal" "rdi_failover_vpc_endpoint_service_allowed_principal" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.rdi_failover_vpc_endpoint_service.id
  principal_arn = # TODO
}

# TODO: create aurora postgres DB
# TODO: make parameters pluggable
