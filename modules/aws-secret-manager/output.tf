output "secret_arn" {
  value = resource.aws_secretsmanager_secret.rdi_secret.arn
}

output "private_key_secret_arn" {
  value       = var.private_key != null ? nonsensitive(aws_secretsmanager_secret.rdi_private_key_secret[0].arn) : null
  description = "ARN of the private key secret (Snowflake key-pair auth). Null when using password auth."
}

output "ca_cert_secret_arn" {
  value       = var.ca_cert != null ? nonsensitive(aws_secretsmanager_secret.rdi_ca_cert_secret[0].arn) : null
  description = "ARN of the CA certificate secret. Null when using the default system CAs."
}

output "kms_key_arn" {
  value = resource.aws_kms_key.rdi_key.arn
}
