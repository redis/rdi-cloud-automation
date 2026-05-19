variable "identifier" {
  description = "Unique identifier for this database. Used as a prefix in every resource name."
  type        = string
}

variable "engine" {
  description = "Database engine. One of: aurora-postgres, aurora-mysql, postgres, mysql, mariadb, oracle, sqlserver."
  type        = string
  validation {
    condition     = contains(["aurora-postgres", "aurora-mysql", "postgres", "mysql", "mariadb", "oracle", "sqlserver"], var.engine)
    error_message = "engine must be one of: aurora-postgres, aurora-mysql, postgres, mysql, mariadb, oracle, sqlserver."
  }
}

variable "engine_version" {
  description = "Specific engine version. If null, the latest minor version for the engine's major track is used."
  type        = string
  default     = null
}

variable "port" {
  description = "Database port. If null, uses the engine's standard port (5432 / 3306 / 1521 / 1433)."
  type        = number
  default     = null
}

variable "instance_class" {
  description = "RDS instance class. If null, a sensible default is chosen per engine."
  type        = string
  default     = null
}

variable "aurora_instance_count" {
  description = "Number of cluster instances for Aurora engines. 1 (default) = writer only, cheaper for dev. 2 = writer + reader for HA. Ignored on non-Aurora engines."
  type        = number
  default     = 1
}

variable "db_password" {
  description = "Master password for the database. Generate one per DB in the caller."
  type        = string
  sensitive   = true
}

variable "network" {
  description = "Shared VPC, subnets, and DB subnet group - the outputs of the aws-rdi-network module."
  type = object({
    vpc_id                     = string
    public_subnet_ids          = list(string)
    database_subnet_group_name = string
  })
}

variable "redis_secrets_arn" {
  description = "AWS principal allowed to read the credentials secret. null = no resource policy (closed); \"*\" = wide-open; a specific ARN = scoped to that principal."
  type        = string
  default     = null
}

variable "redis_privatelink_arn" {
  description = "AWS principal allowed to consume the PrivateLink endpoint. null = no consumers allowed; \"*\" = any AWS account; a specific ARN = scoped to that principal."
  type        = string
  default     = null
}

variable "public_access" {
  description = "If true, the NLB is internet-facing and the SG opens the DB port to allowed_cidrs. If false, the NLB is private (PrivateLink-only)."
  type        = bool
  default     = false
}

variable "allowed_cidrs" {
  description = "CIDR blocks permitted to reach the DB port when public_access = true. Ignored when public_access = false."
  type        = list(string)
  default     = []
}

variable "database_name" {
  description = "Override the default database name created on this instance. If null, uses the engine default (chinook for Postgres/MySQL, ORCL for Oracle, none for SQL Server). SQL Server does not support setting db_name at creation - leave null."
  type        = string
  default     = null
}

variable "init_sql_file" {
  description = "Optional path to a SQL file imported into the engine-default database after provisioning. Path is resolved from the calling root module's directory (path.root). MySQL engines only; ignored for others. Requires public_access = true (or terraform running from inside the VPC) since it connects via the NLB."
  type        = string
  default     = null
}
