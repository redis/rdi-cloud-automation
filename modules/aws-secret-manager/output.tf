output "secret_arn" {
  value = resource.aws_secretsmanager_secret.rdi_secret.arn
}

output "kms_key_arn" {
  value = resource.aws_kms_key.rdi_key.arn
}
