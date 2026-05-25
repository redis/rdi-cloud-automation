variable "identifier" {
  type = string
}

variable "allowed_principals" {
  type = list(string)
}

variable "username" {
  type = string
}

variable "password" {
  description = "Password for username/password authentication. Set to null when using key-pair authentication."
  type        = string
  sensitive   = true
  default     = null
}

variable "private_key" {
  description = "PEM-encoded PKCS8 private key for Snowflake key-pair authentication. When set, a separate secret is created containing the raw PEM content (mounted as client.key). Leave null for password authentication."
  type        = string
  sensitive   = true
  default     = null
}

variable "ca_cert" {
  description = "PEM-encoded CA certificate bundle to trust for TLS connections (e.g. MongoDB Atlas CA). When set, a separate secret is created containing the raw PEM content (mounted as ca.crt). Leave null when the default system CAs are sufficient."
  type        = string
  sensitive   = true
  default     = null
}

variable "kms_key_id" {
  description = "ARN of an existing KMS key to use for the secret. If null, a new key is created."
  type        = string
  default     = null
}
