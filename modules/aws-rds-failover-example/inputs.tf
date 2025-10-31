variable "identifier" {
  type        = string
  description = "A unique identifier for the resources created by this module"
}

variable "region" {
  type        = string
  description = "AWS region for the resources"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
  default     = "dev"
}

# Lambda variables
variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "python3.11"
}

variable "lambda_handler" {
  type        = string
  description = "Lambda function entry point"
  default     = "index.handler"
}

variable "lambda_source_path" {
  type        = string
  description = "Path to the Lambda function source code (zip file or directory)"
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 30
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda function memory size in MB"
  default     = 128
}

variable "lambda_environment_variables" {
  type        = map(string)
  description = "Environment variables for the Lambda function"
  default     = {}
}

# SNS variables
variable "sns_topic_name" {
  type        = string
  description = "Name of the SNS topic"
  default     = "rdi-failover-topic"
}

# RDS Aurora variables
variable "db_instance_class" {
  type        = string
  description = "Instance class for RDS Aurora"
  default     = "db.t3.medium"
}

variable "db_engine_version" {
  type        = string
  description = "Aurora PostgreSQL engine version"
  default     = "15.3"
}

variable "db_master_username" {
  type        = string
  description = "Master username for the database"
  default     = "postgres"
}

variable "db_master_password" {
  type        = string
  description = "Master password for the database"
  sensitive   = true
}

variable "db_port" {
  type        = number
  description = "Database port"
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Name of the default database"
  default     = "postgres"
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention period in days"
  default     = 7
}

variable "backup_window" {
  type        = string
  description = "Backup window"
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  type        = string
  description = "Maintenance window"
  default     = "mon:04:00-mon:05:00"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on deletion"
  default     = false
}

# VPC and Networking
variable "vpc_id" {
  type        = string
  description = "VPC ID for the RDS cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the RDS cluster"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs allowed to access the database"
  default     = []
}

# CloudWatch Event Rule variables
variable "cloudwatch_schedule_expression" {
  type        = string
  description = "Schedule expression for CloudWatch Events (e.g., 'rate(1 hour)' or 'cron(0 12 * * ? *)')"
  default     = "rate(1 hour)"
}

variable "enabled" {
  type        = bool
  description = "Whether the CloudWatch event rule is enabled"
  default     = true
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}

