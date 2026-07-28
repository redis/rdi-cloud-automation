variable "region" {
  description = "AWS region for the PrivateLink producer resources."
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use. If null, the AWS provider falls back to the default credential chain."
  type        = string
  default     = null
}

variable "name" {
  description = "Unique name for resources created by this example. Must be valid for NLB and target group names."
  type        = string

  validation {
    condition = (
      length(var.name) >= 1 &&
      length(var.name) <= 32 &&
      can(regex("^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$", var.name)) &&
      !startswith(var.name, "internal-")
    )
    error_message = "name must be 1-32 chars, use only letters/numbers/hyphens, not start or end with a hyphen, and not start with internal-."
  }
}

variable "vpc_id" {
  description = "VPC ID where the existing database is reachable and where the NLB should be created."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the NLB. For PrivateLink-only access these are normally private subnets in the database VPC."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet."
  }
}

variable "db_port" {
  description = "Database listener port, for example 5432, 3306, 1521, or 1433."
  type        = number

  validation {
    condition     = var.db_port >= 1 && var.db_port <= 65535
    error_message = "db_port must be a valid TCP port."
  }
}

variable "db_endpoint" {
  description = "Existing database DNS endpoint. Optional for RDS/Aurora if rds_identifier is supplied and lookup succeeds; required for RDS failover target refresh otherwise."
  type        = string
  default     = null

  validation {
    condition     = var.db_endpoint == null || trimspace(var.db_endpoint) != ""
    error_message = "db_endpoint must not be empty when set."
  }
}

variable "target_type" {
  description = "NLB target type. Use ip for RDS/Aurora/static IP targets, or instance for EC2-hosted databases."
  type        = string
  default     = "ip"

  validation {
    condition     = contains(["ip", "instance"], var.target_type)
    error_message = "target_type must be either ip or instance."
  }
}

variable "static_targets" {
  description = "Targets to register when enable_rds_failover_lambda = false. Values are IP addresses for target_type=ip or instance IDs for target_type=instance."
  type        = map(string)
  default     = {}
}

variable "enable_rds_failover_lambda" {
  description = "When true, create a Lambda that keeps the NLB target group synced with the current RDS/Aurora endpoint IPs."
  type        = bool
  default     = true
}

variable "rds_source_type" {
  description = "RDS event source type used by the failover Lambda. Use db-cluster for Aurora or db-instance for standalone RDS."
  type        = string
  default     = "db-cluster"

  validation {
    condition     = contains(["db-cluster", "db-instance"], var.rds_source_type)
    error_message = "rds_source_type must be db-cluster or db-instance."
  }
}

variable "rds_identifier" {
  description = "Existing Aurora cluster identifier or RDS instance identifier. Used for data-source lookup and RDS event subscription."
  type        = string
  default     = null

  validation {
    condition     = var.rds_identifier == null || trimspace(var.rds_identifier) != ""
    error_message = "rds_identifier must not be empty when set."
  }
}

variable "rds_source_id" {
  description = "Optional explicit source ID for the RDS event subscription. Defaults to rds_identifier or the looked-up source identifier."
  type        = string
  default     = null

  validation {
    condition     = var.rds_source_id == null || trimspace(var.rds_source_id) != ""
    error_message = "rds_source_id must not be empty when set."
  }
}

variable "redis_privatelink_arn" {
  description = "Redis Cloud AWS principal ARN(s) allowed to create a PrivateLink endpoint to this service. Use the value from the Redis Cloud RDI UI."
  type        = any
  nullable    = false

  validation {
    condition = (
      try(trimspace(tostring(var.redis_privatelink_arn)) != "", false) ||
      try(length(tolist(var.redis_privatelink_arn)) > 0 && alltrue([for arn in tolist(var.redis_privatelink_arn) : trimspace(tostring(arn)) != ""]), false)
    )
    error_message = "redis_privatelink_arn is required and must be a non-empty ARN string or non-empty list of ARN strings."
  }
}

variable "redis_secrets_arn" {
  description = "Redis Cloud AWS principal ARN(s) allowed to read the credentials secret. Use the value from the Redis Cloud RDI UI."
  type        = any
  nullable    = false

  validation {
    condition = (
      try(trimspace(tostring(var.redis_secrets_arn)) != "", false) ||
      try(length(tolist(var.redis_secrets_arn)) > 0 && alltrue([for arn in tolist(var.redis_secrets_arn) : trimspace(tostring(arn)) != ""]), false)
    )
    error_message = "redis_secrets_arn is required and must be a non-empty ARN string or non-empty list of ARN strings."
  }
}

variable "acceptance_required" {
  description = "Whether each PrivateLink endpoint connection request must be manually accepted."
  type        = bool
  default     = false
}

variable "nlb_internal" {
  description = "Whether the NLB is internal. Keep true for PrivateLink-only access."
  type        = bool
  default     = true
}

variable "manage_security_group_rule" {
  description = "When true, add ingress from the new NLB security group to every DB security group in db_security_group_ids."
  type        = bool
  default     = false
}

variable "db_security_group_ids" {
  description = "Existing database security groups to update when manage_security_group_rule = true."
  type        = list(string)
  default     = []
}

variable "create_secret" {
  description = "When true, create a Secrets Manager secret for the RDI database credentials. When false, set existing_secret_arn."
  type        = bool
  default     = true
}

variable "manage_secret_value_after_creation" {
  description = "When false, Terraform creates an initial placeholder secret value and then ignores future secret_string changes so users can edit credentials in Secrets Manager. When true, Terraform manages rdi_username/rdi_password on every apply."
  type        = bool
  default     = false
}

variable "existing_secret_arn" {
  description = "Existing Secrets Manager secret ARN to use when create_secret = false."
  type        = string
  default     = null

  validation {
    condition     = var.existing_secret_arn == null || trimspace(var.existing_secret_arn) != ""
    error_message = "existing_secret_arn must not be empty when set."
  }
}

variable "rdi_username" {
  description = "Initial username written to the created secret. In the default bootstrap mode, replace the placeholder in Secrets Manager after apply."
  type        = string
  default     = "<put username here>"
}

variable "rdi_password" {
  description = "Initial password written to the created secret. In the default bootstrap mode, replace the placeholder in Secrets Manager after apply."
  type        = string
  sensitive   = true
  default     = "<put password here>"
}

variable "tags" {
  description = "Tags to apply to resources created directly by this example."
  type        = map(string)
  default     = {}
}
