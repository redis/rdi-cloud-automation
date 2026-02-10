variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/20"
}

variable "azs" {
  description = "A list of availability zones to deploy the RDS instance into"
  type        = list(string)
  default     = ["use1-az2", "use1-az4", "use1-az6"]
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = list(string)
  default     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

variable "database_subnet_cidr" {
  description = "The CIDR block for the database subnet"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "identifier" {
  description = "The identifier for the resources/test"
  type        = string
}

variable "db_password" {
  description = "The password for connecting to the SQL Server Database"
  type        = string
}

variable "db_port" {
  description = "The port for connecting to the SQL Server Database"
  type        = number
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database. WARNING: Default allows access from anywhere (0.0.0.0/0) for testing purposes only. In production, restrict to specific IP ranges."
  type        = list(string)
  default     = ["0.0.0.0/0"]  # WARNING: Open to internet - for testing only!
}

