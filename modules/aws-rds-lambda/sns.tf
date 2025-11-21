# SNS Topic
resource "aws_sns_topic" "rdi_failover_topic" {
  name         = var.identifier
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

resource "aws_db_event_subscription" "rds_cluster_failover_event" {
  name             = "${var.identifier}-rds-cluster-events"
  sns_topic        = aws_sns_topic.rdi_failover_topic.arn
  event_categories = ["creation", "failover", "failure"]
  source_type      = "db-cluster"
  source_ids       = [split(".", var.db_endpoint)[0]]
  enabled          = true
}

action "aws_lambda_invoke" "initial" {
  config {
    function_name = aws_lambda_function.rdi_failover_lambda.function_name
  }
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rdi_failover_lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.rdi_failover_topic.arn
}
