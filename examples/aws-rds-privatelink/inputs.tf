variable "region" {
  type = string
}

variable "port" {
  type = number
}

variable "name" {
  type = string
}

variable "redis_secrets_arn" {
  type = string
  validation {
    condition     = var.redis_secrets_arn != ""
    error_message = "redis_secrets_arn must be configured with the ARN from the UI"
  }
}

variable "redis_privatelink_arn" {
  type = string
  validation {
    condition     = var.redis_privatelink_arn != ""
    error_message = "redis_privatelink_arn must be configured with the ARN from the UI"
  }
}

variable "azs" {
  type = list(string)
}
