variable "identifier" {
  type = string
}

variable "allowed_principals" {
  type = list(string)
}

variable "kms_key_mode" {
  description = "How to provision the KMS key used by the secret. Use 'managed' to create it, or 'existing' to use existing_kms_key_arn."
  type        = string
  default     = "managed"

  validation {
    condition     = contains(["managed", "existing"], var.kms_key_mode)
    error_message = "kms_key_mode must be either 'managed' or 'existing'."
  }
}

variable "existing_kms_key_arn" {
  description = "Existing KMS key ARN. Required when kms_key_mode = 'existing'."
  type        = string
  default     = null
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}
