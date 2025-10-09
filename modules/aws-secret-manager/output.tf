output "secret_arn" {
  value = resource.aws_secretsmanager_secret.rdi_secret.arn
}
