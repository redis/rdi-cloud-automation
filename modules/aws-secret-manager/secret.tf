resource "aws_secretsmanager_secret" "rdi_secret" {
  name       = var.identifier
  kms_key_id = resource.aws_kms_key.rdi_key.arn
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [for p in var.allowed_principals :
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:PrincipalArn" : p
          }
        }
    }]
  })
}

resource "aws_secretsmanager_secret_version" "rdi_secret" {
  secret_id = aws_secretsmanager_secret.rdi_secret.id
  secret_string = jsonencode({
    "username" : var.username,
    "password" : var.password,
  })
}

# Private key secret for Snowflake key-pair authentication.
# Stores the raw PEM content; the RDI operator mounts it as client.key via External Secrets.
resource "aws_secretsmanager_secret" "rdi_private_key_secret" {
  count      = var.private_key != null ? 1 : 0
  name       = "${var.identifier}-private-key"
  kms_key_id = resource.aws_kms_key.rdi_key.arn
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [for p in var.allowed_principals :
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:PrincipalArn" : p
          }
        }
    }]
  })
}

resource "aws_secretsmanager_secret_version" "rdi_private_key_secret" {
  count         = var.private_key != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.rdi_private_key_secret[0].id
  secret_string = var.private_key
}

# CA certificate secret for custom TLS trust (e.g. MongoDB Atlas CA).
# Stores the raw PEM content; the RDI operator mounts it as ca.crt via External Secrets.
resource "aws_secretsmanager_secret" "rdi_ca_cert_secret" {
  count      = var.ca_cert != null ? 1 : 0
  name       = "${var.identifier}-ca-cert"
  kms_key_id = resource.aws_kms_key.rdi_key.arn
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [for p in var.allowed_principals :
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:PrincipalArn" : p
          }
        }
    }]
  })
}

resource "aws_secretsmanager_secret_version" "rdi_ca_cert_secret" {
  count         = var.ca_cert != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.rdi_ca_cert_secret[0].id
  secret_string = var.ca_cert
}
