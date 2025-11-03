data "aws_caller_identity" "current" {}

resource "aws_kms_key" "rdi_key" {
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = ""
    Statement = concat([
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
      ],
      [for p in var.allowed_principals :
        {
          "Sid" : p,
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : join(":", concat(slice(split(":", p), 0, 5), ["root"]))
          },
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : "*"
        }
    ])
  })
}
