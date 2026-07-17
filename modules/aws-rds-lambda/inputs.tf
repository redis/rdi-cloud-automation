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

variable "rds_arn" {
  type = string
}

variable "rds_cluster_identifier" {
  description = "The RDS cluster or instance identifier for the event subscription (always points to RDS, not proxy)"
  type        = string
}

variable "source_type" {
  description = "RDS event source type. 'db-cluster' for Aurora clusters; 'db-instance' for standalone RDS instances."
  type        = string
  default     = "db-cluster"
  validation {
    condition     = contains(["db-cluster", "db-instance"], var.source_type)
    error_message = "source_type must be 'db-cluster' or 'db-instance'."
  }
}
