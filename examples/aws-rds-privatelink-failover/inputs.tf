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

variable "db_engine" {
  description = "Database engine to use: 'postgres', 'mysql', or 'sqlserver'"
  type        = string
  default     = "postgres"
  validation {
    condition     = contains(["postgres", "mysql", "sqlserver"], var.db_engine)
    error_message = "db_engine must be one of: 'postgres', 'mysql', 'sqlserver'"
  }
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication (optional, can also use AWS_PROFILE env var)"
  type        = string
  default     = null
}

variable "use_rds_proxy" {
  description = "DEPRECATED: Enable RDS Proxy between NLB and RDS. RDS Proxy is deprecated and not recommended for new deployments. Default: false"
  type        = bool
  default     = false
}

variable "rds_proxy_require_tls" {
  description = "Whether to require TLS for connections to RDS Proxy. Only applies when use_rds_proxy = true. Default: false"
  type        = bool
  default     = false
}

variable "nlb_internal" {
  description = "Whether the NLB should be internal (private, PrivateLink only) or internet-facing (public, direct access). Default: true (private)"
  type        = bool
  default     = true
}
