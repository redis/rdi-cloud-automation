resource "aws_secretsmanager_secret" "rdi_secret" {
  name       = var.identifier
  kms_key_id = resource.aws_kms_key.rdi_key.arn
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "RedisDataIntegrationRoleAccess",
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource" : "*",
      "Condition" : {
        "StringLike" : {
          "aws:PrincipalArn" : "arn:aws:iam::${var.redis_account}:role/redis-data-pipeline-secrets-role"
        }
      }
    }]
  })
}

resource "aws_secretsmanager_secret_version" "rdi_secret" {
  secret_id = aws_secretsmanager_secret.rdi_secret.id
  secret_string = jsonencode({
    "username" : var.username,
    "password" : var.password
  })
}
