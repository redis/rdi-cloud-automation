variable "identifier" {
  description = "The identifier for the resources/test"
  type        = string
}

variable "db_endpoint" {
  type = string
}

variable "db_port" {
  type = number
}

variable "elb_tg_arn" {
  type = string
}

variable "lambda_role_mode" {
  description = "How to provision the Lambda execution role. Use 'managed' to create it, or 'existing' to use lambda_execution_role_arn."
  type        = string
  default     = "managed"

  validation {
    condition     = contains(["managed", "existing"], var.lambda_role_mode)
    error_message = "lambda_role_mode must be either 'managed' or 'existing'."
  }
}

variable "lambda_execution_role_arn" {
  description = "Existing Lambda execution role ARN. Required when lambda_role_mode = 'existing'."
  type        = string
  default     = null
}

variable "rds_cluster_identifier" {
  description = "The RDS event source identifier for event subscription (always points to RDS, not proxy)"
  type        = string
}

variable "rds_event_source_type" {
  description = "The RDS event source type for failover subscriptions."
  type        = string
  default     = "db-cluster"

  validation {
    condition     = contains(["db-cluster", "db-instance"], var.rds_event_source_type)
    error_message = "rds_event_source_type must be either 'db-cluster' or 'db-instance'."
  }
}
