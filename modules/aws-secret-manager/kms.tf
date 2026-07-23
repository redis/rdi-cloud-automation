data "aws_caller_identity" "current" {}

locals {
  create_kms_key = var.kms_key_mode == "managed"
  kms_key_arn    = local.create_kms_key ? aws_kms_key.rdi_key[0].arn : var.existing_kms_key_arn
}

resource "terraform_data" "validate_kms_key" {
  input = {
    kms_key_mode         = var.kms_key_mode
    existing_kms_key_arn = var.existing_kms_key_arn
  }

  lifecycle {
    precondition {
      condition     = var.kms_key_mode == "managed" || try(length(trimspace(var.existing_kms_key_arn)) > 0, false)
      error_message = "existing_kms_key_arn must be set when kms_key_mode = \"existing\"."
    }
  }
}

resource "aws_kms_key" "rdi_key" {
  count = local.create_kms_key ? 1 : 0

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
