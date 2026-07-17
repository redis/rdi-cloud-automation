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
  name      = "${var.identifier}-rds-cluster-events"
  sns_topic = aws_sns_topic.rdi_failover_topic.arn
  # Include "configuration change" + "maintenance" so multi-AZ conversion and
  # AZ migrations fire the Lambda too - not just failover events.
  event_categories = ["creation", "failover", "failure", "configuration change", "maintenance"]
  source_type      = var.source_type
  source_ids       = [var.rds_cluster_identifier]
  enabled          = true
}

# Re-invoke the lambda whenever the RDS endpoint or target group changes.
# Without this trigger, recreating the RDS resource (or any path that doesn't
# emit an RDS event) leaves the NLB pointing at the old IP. The lambda ignores
# the payload - it always re-resolves from env vars - but the input change
# forces terraform to re-run it.
resource "aws_lambda_invocation" "initial" {
  function_name = aws_lambda_function.rdi_failover_lambda.function_name
  input = jsonencode({
    db_endpoint = var.db_endpoint
    elb_tg_arn  = var.elb_tg_arn
    db_port     = var.db_port
  })
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rdi_failover_lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.rdi_failover_topic.arn
}
