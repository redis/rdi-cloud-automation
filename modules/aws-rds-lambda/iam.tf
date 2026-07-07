locals {
  create_lambda_execution_role = var.lambda_role_mode == "managed"
  lambda_execution_role_arn    = local.create_lambda_execution_role ? aws_iam_role.lambda_execution_role[0].arn : var.lambda_execution_role_arn
}

resource "terraform_data" "validate_lambda_execution_role" {
  input = {
    lambda_role_mode          = var.lambda_role_mode
    lambda_execution_role_arn = var.lambda_execution_role_arn
  }

  lifecycle {
    precondition {
      condition     = var.lambda_role_mode == "managed" || try(length(trimspace(var.lambda_execution_role_arn)) > 0, false)
      error_message = "lambda_execution_role_arn must be set when lambda_role_mode = \"existing\"."
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  count = local.create_lambda_execution_role ? 1 : 0

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
  count = local.create_lambda_execution_role ? 1 : 0

  name = "${var.identifier}-ec2-elb-lambda-execution-role-policy"
  role = aws_iam_role.lambda_execution_role[0].id
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
  count = local.create_lambda_execution_role ? 1 : 0

  name = "${var.identifier}-log-group-lambda-execution-role-policy"
  role = aws_iam_role.lambda_execution_role[0].id
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
