resource "aws_lambda_function" "rdi_failover_lambda" {
  filename      = data.archive_file.rdi_failover_lambda.output_path
  function_name = var.identifier
  role          = local.lambda_execution_role_arn
  handler       = "lambda.lambda_handler"
  environment {
    variables = {
      Cluster_EndPoint = var.db_endpoint
      RDS_Port         = var.db_port
      NLB_TG_ARN       = var.elb_tg_arn
    }
  }
  runtime     = "python3.12"
  timeout     = 300
  memory_size = 128

  depends_on = [
    aws_cloudwatch_log_group.rdi,
    aws_iam_role_policy.ec2_elb_lambda_execution_role_policy,
    aws_iam_role_policy.log_group_lambda_execution_role_policy,
    terraform_data.validate_lambda_execution_role
  ]
}

resource "aws_cloudwatch_log_group" "rdi" {
  name              = "/aws/lambda/${var.identifier}"
  retention_in_days = 14
}

data "archive_file" "rdi_failover_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/function.zip"
}
