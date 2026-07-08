output "secret_arn" {
  value = resource.aws_secretsmanager_secret.rdi_secret.arn
}

output "kms_key_arn" {
  value = local.kms_key_arn
}
