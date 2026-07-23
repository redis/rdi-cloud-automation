variable "region" {
  type = string
}

variable "port" {
  type = number
}

variable "source_db_mode" {
  description = "Database source mode. Use 'demo' to create the sample Aurora/RDS database, or 'existing' to connect Redis Cloud RDI to an existing customer-owned RDS/Aurora database."
  type        = string
  default     = "demo"

  validation {
    condition     = contains(["demo", "existing"], var.source_db_mode)
    error_message = "source_db_mode must be either 'demo' or 'existing'."
  }
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
  description = "Availability zones used when source_db_mode = 'demo'. Not used for existing databases."
  type        = list(string)
  default     = []
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

variable "lambda_role_mode" {
  description = "How to provision the failover Lambda execution role. Use 'managed' to let Terraform create IAM resources, or 'existing' to use an admin-provided role ARN."
  type        = string
  default     = "managed"

  validation {
    condition     = contains(["managed", "existing"], var.lambda_role_mode)
    error_message = "lambda_role_mode must be either 'managed' or 'existing'."
  }
}

variable "existing_lambda_execution_role_arn" {
  description = "Existing Lambda execution role ARN to use when lambda_role_mode = 'existing'. The Terraform runner still needs iam:PassRole for this role."
  type        = string
  default     = null
}

variable "kms_key_mode" {
  description = "How to provision the KMS key used by Secrets Manager. Use 'managed' to let Terraform create it, or 'existing' to use an admin-provided key ARN."
  type        = string
  default     = "managed"

  validation {
    condition     = contains(["managed", "existing"], var.kms_key_mode)
    error_message = "kms_key_mode must be either 'managed' or 'existing'."
  }
}

variable "existing_kms_key_arn" {
  description = "Existing KMS key ARN to use when kms_key_mode = 'existing'. The key policy must allow Secrets Manager use and decrypt access for Redis Cloud."
  type        = string
  default     = null
}

variable "nlb_internal" {
  description = "Whether the NLB should be internal (private, PrivateLink only) or internet-facing (public, direct access). Default: true (private)"
  type        = bool
  default     = true
}

variable "existing_db" {
  description = "Connection and networking metadata for source_db_mode = 'existing'. The NLB must be created in the same VPC as the database targets. Provide either subnet_ids or subnet_lookup."
  type = object({
    hostname   = string
    username   = string
    database   = string
    vpc_id     = string
    subnet_ids = optional(list(string), [])
    subnet_lookup = optional(object({
      azs  = list(string)
      tags = optional(map(string), {})
    }))
    db_security_group_ids = list(string)
    rds_event_source_id   = string
    rds_event_source_type = optional(string, "db-cluster")
  })
  default = null

  validation {
    condition = var.existing_db == null || contains(
      ["db-cluster", "db-instance"],
      var.existing_db.rds_event_source_type
    )
    error_message = "existing_db.rds_event_source_type must be either 'db-cluster' or 'db-instance'."
  }

  validation {
    condition = var.existing_db == null || (
      length(var.existing_db.subnet_ids) > 0 ||
      try(length(var.existing_db.subnet_lookup.azs), 0) > 0
    )
    error_message = "existing_db must include either subnet_ids or subnet_lookup.azs."
  }

  validation {
    condition = var.existing_db == null || !(
      length(var.existing_db.subnet_ids) > 0 &&
      try(length(var.existing_db.subnet_lookup.azs), 0) > 0
    )
    error_message = "existing_db must use either subnet_ids or subnet_lookup.azs, not both."
  }
}

variable "existing_db_password" {
  description = "Password for existing_db.username when source_db_mode = 'existing'. This is stored in AWS Secrets Manager for Redis Cloud RDI."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_existing_db_security_group_ingress" {
  description = "Whether Terraform should add an ingress rule to existing_db.db_security_group_ids allowing traffic from the generated NLB security group."
  type        = bool
  default     = false
}

variable "nlb_ingress_cidr_blocks" {
  description = "Optional CIDR blocks allowed to reach the NLB directly. Leave empty for PrivateLink-only access."
  type        = list(string)
  default     = []
}
